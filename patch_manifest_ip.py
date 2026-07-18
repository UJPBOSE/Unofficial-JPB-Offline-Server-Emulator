#!/usr/bin/env python3
"""Generate or patch local cache manifest + onlineoptions for this machine.

Usage:
  python patch_manifest_ip.py NEW_PC_LAN_IP
  python patch_manifest_ip.py NEW_PC_LAN_IP --regenerate

Creates (or refreshes) gitignored local files:
  - fixed_manifest.json  from cache_files/*.dab|*.dhr|*.dsb
  - onlineoptions        from built-in online_options_defaults.py

Those generated files should not be committed.
"""
from __future__ import annotations

import hashlib
import ipaddress
import json
import ntpath
import os
import re
import shutil
import struct
import sys
from urllib.parse import urlsplit

from online_options_defaults import (
    ONLINE_OPTIONS_DEFAULT_PAIRS,
    ONLINE_OPTIONS_HEADER_HEX,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MANIFEST_FILE = os.path.join(BASE_DIR, "fixed_manifest.json")
CACHE_DIR = os.path.join(BASE_DIR, "cache_files")
ONLINE_OPTIONS_FILE = os.path.join(BASE_DIR, "onlineoptions")

PACKAGE_EXTENSIONS = (".dab", ".dhr", ".dsb")
# Match historical Ludia package block naming / listing order.
BLOCK_BY_EXT = {
    ".dab": "asynchronous",
    ".dhr": "header",
    ".dsb": "synchronous",
}
EXT_ORDER = (".dab", ".dhr", ".dsb")
MANIFEST_VERSION = "3"
DEFAULT_HTTP_PORT = 9943
ONLINE_OPTIONS_KEY_MARKER = b"\x01\x00\x00\x00k\x04\x00\x00\x00"
ONLINE_OPTIONS_VALUE_MARKER = b"\x01\x00\x00\x00v\x04\x00\x00\x00"


def _url_values(value):
    if isinstance(value, dict):
        for key, item in value.items():
            if str(key).lower() == "url" and isinstance(item, str):
                yield item
            else:
                yield from _url_values(item)
    elif isinstance(value, list):
        for item in value:
            yield from _url_values(item)


def _manifest_ipv4_hosts(document):
    hosts = set()
    for url in _url_values(document):
        hostname = urlsplit(url).hostname
        if not hostname:
            continue
        try:
            address = ipaddress.ip_address(hostname)
        except ValueError:
            continue
        if isinstance(address, ipaddress.IPv4Address):
            hosts.add(str(address))
    return sorted(hosts)


def _file_md5(path):
    digest = hashlib.md5()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _atomic_write_text(path, text, output=print):
    backup = path + ".pre-ip-patch.bak"
    temp_file = path + ".tmp"
    if os.path.isfile(path):
        shutil.copy2(path, backup)
        output(f"Backup: {backup}")
    try:
        with open(temp_file, "w", encoding="utf-8", newline="") as handle:
            handle.write(text)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_file, path)
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


def _atomic_write_bytes(path, data, output=print):
    backup = path + ".pre-ip-patch.bak"
    temp_file = path + ".tmp"
    if os.path.isfile(path):
        shutil.copy2(path, backup)
        output(f"Backup: {backup}")
    try:
        with open(temp_file, "wb") as handle:
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temp_file, path)
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)


def encode_online_option_pair(key, value):
    key_bytes = str(key).encode("utf-8")
    value_bytes = str(value).encode("utf-8")
    return (
        ONLINE_OPTIONS_KEY_MARKER
        + struct.pack("<I", len(key_bytes))
        + key_bytes
        + ONLINE_OPTIONS_VALUE_MARKER
        + struct.pack("<I", len(value_bytes))
        + value_bytes
    )


def load_online_options_defaults():
    header = bytes.fromhex(ONLINE_OPTIONS_HEADER_HEX)
    pairs = [(str(key), str(value)) for key, value in ONLINE_OPTIONS_DEFAULT_PAIRS]
    if not pairs:
        raise ValueError("ONLINE_OPTIONS_DEFAULT_PAIRS is empty")
    return header, pairs


def build_onlineoptions_from_defaults():
    header, pairs = load_online_options_defaults()
    return header + b"".join(encode_online_option_pair(key, value) for key, value in pairs)


def generate_onlineoptions(
    output_file=ONLINE_OPTIONS_FILE,
    output=print,
    force=False,
):
    if os.path.isfile(output_file) and not force:
        output(f"onlineoptions already exists; leaving unchanged: {output_file}")
        return 0
    try:
        body = build_onlineoptions_from_defaults()
    except (ValueError, TypeError) as exc:
        output(f"Could not build onlineoptions: {type(exc).__name__}: {exc}")
        return 1
    _atomic_write_bytes(output_file, body, output)
    output(f"Wrote {output_file} ({len(body)} bytes, from built-in defaults)")
    return 0


def _list_package_cache_files(cache_dir):
    names = []
    for name in os.listdir(cache_dir):
        path = os.path.join(cache_dir, name)
        if not os.path.isfile(path):
            continue
        if os.path.splitext(name)[1].lower() not in PACKAGE_EXTENSIONS:
            continue
        if os.path.basename(name) != name or ntpath.basename(name) != name:
            continue
        names.append(name)
    return names


def build_manifest_from_cache(
    lan_ip,
    cache_dir=None,
    http_port=DEFAULT_HTTP_PORT,
    output=print,
):
    if cache_dir is None:
        cache_dir = CACHE_DIR
    try:
        normalized_ip = str(ipaddress.IPv4Address(str(lan_ip).strip()))
    except ipaddress.AddressValueError:
        output(f"Invalid IPv4 address: {lan_ip!r}")
        return None, 2

    if not os.path.isdir(cache_dir):
        output(f"Cache directory not found: {cache_dir}")
        output("Put your Android-shaped .dab/.dhr/.dsb packs in cache_files/ first.")
        return None, 1

    try:
        package_names = _list_package_cache_files(cache_dir)
    except OSError as exc:
        output(f"Could not scan cache directory: {type(exc).__name__}: {exc}")
        return None, 1

    if not package_names:
        output(f"No package files (.dab/.dhr/.dsb) found in {cache_dir}")
        return None, 1

    by_stem = {}
    for name in package_names:
        stem, ext = os.path.splitext(name)
        by_stem.setdefault(stem, {})[ext.lower()] = name

    document = []
    for stem in sorted(by_stem, key=str.casefold):
        files = by_stem[stem]
        for ext in EXT_ORDER:
            filename = files.get(ext)
            if filename is None:
                continue
            path = os.path.join(cache_dir, filename)
            try:
                size = str(os.path.getsize(path))
                checksum = _file_md5(path)
            except OSError as exc:
                output(f"Could not read {filename!r}: {type(exc).__name__}: {exc}")
                return None, 1
            package_name = os.path.splitext(filename)[0]
            document.append(
                {
                    "url": (
                        f"http://{normalized_ip}:{int(http_port)}"
                        f"/jp/local_path/{filename}"
                    ),
                    "metadata": (
                        f"package={package_name};block={BLOCK_BY_EXT[ext]}"
                    ),
                    "filename": filename,
                    "checksum": checksum,
                    "size": size,
                    "tags": [],
                    "version": MANIFEST_VERSION,
                }
            )

    output(
        f"Generated manifest entries={len(document)} "
        f"packages={len(by_stem)} ip={normalized_ip} port={int(http_port)}"
    )
    return document, 0


def write_manifest(document, manifest_file=MANIFEST_FILE, output=print):
    text = json.dumps(document, ensure_ascii=True, separators=(",", ":"))
    _atomic_write_text(manifest_file, text, output)
    output(f"Wrote {manifest_file}")
    return 0


def reconcile_manifest_cache(document, cache_dir, output=print):
    report = {
        "entries": len(document) if isinstance(document, list) else 0,
        "matched": 0,
        "updated": 0,
        "missing": [],
        "unsafe": [],
        "unreadable": [],
        "unlisted": [],
        "ignored": [],
        "duplicates": [],
        "url_mismatches": [],
        "scanned": False,
        "valid": False,
    }
    if not os.path.isdir(cache_dir):
        output(f"Cache directory not found: {cache_dir}")
        report["valid"] = True
        return report
    if not isinstance(document, list):
        output("Manifest root is not an array; cache metadata cannot be reconciled.")
        return report

    try:
        all_cache_files = {
            name: os.path.join(cache_dir, name)
            for name in os.listdir(cache_dir)
            if os.path.isfile(os.path.join(cache_dir, name))
        }
    except OSError as exc:
        output(f"Could not scan cache directory: {exc}")
        return report

    report["scanned"] = True
    cache_files = {
        name: path
        for name, path in all_cache_files.items()
        if os.path.splitext(name)[1].lower() in PACKAGE_EXTENSIONS
    }
    report["ignored"] = sorted(set(all_cache_files) - set(cache_files))

    manifest_rows = {}
    casefold_names = {}
    for index, row in enumerate(document):
        if not isinstance(row, dict):
            report["unsafe"].append(f"row[{index}] is {type(row).__name__}")
            continue
        filename = str(row.get("filename", ""))
        if (
            not filename
            or os.path.basename(filename) != filename
            or ntpath.basename(filename) != filename
            or os.path.splitext(filename)[1].lower() not in PACKAGE_EXTENSIONS
        ):
            report["unsafe"].append(filename)
            continue
        folded = filename.casefold()
        if folded in casefold_names:
            report["duplicates"].append((casefold_names[folded], filename))
            continue
        casefold_names[folded] = filename
        manifest_rows[filename] = row

        url_path = urlsplit(str(row.get("url", ""))).path
        url_filename = url_path.rsplit("/", 1)[-1]
        if url_filename != filename:
            report["url_mismatches"].append((filename, url_filename))

    manifest_filenames = set(manifest_rows)
    report["missing"] = sorted(manifest_filenames - set(cache_files))
    report["unlisted"] = sorted(set(cache_files) - manifest_filenames)
    invalid_inventory = bool(
        report["unsafe"]
        or report["duplicates"]
        or report["url_mismatches"]
        or report["unlisted"]
    )
    if invalid_inventory:
        output(
            "Cache metadata scan rejected: manifest/cache package inventory "
            "is not a safe one-to-one match."
        )
        if report["missing"]:
            output(f"Manifest package files missing from cache: {report['missing']!r}")
        if report["unlisted"]:
            output(f"Unlisted cache package files: {report['unlisted']!r}")
        if report["unsafe"]:
            output(f"Rejected unsafe manifest rows/filenames: {report['unsafe']!r}")
        if report["duplicates"]:
            output(f"Duplicate manifest filenames: {report['duplicates']!r}")
        if report["url_mismatches"]:
            output(f"Manifest URL/filename mismatches: {report['url_mismatches']!r}")
        return report
    if report["missing"]:
        output(f"Manifest package files missing from cache: {report['missing']!r}")

    for filename, row in manifest_rows.items():
        cache_path = cache_files.get(filename)
        if cache_path is None:
            continue
        try:
            actual_size = str(os.path.getsize(cache_path))
            actual_checksum = _file_md5(cache_path)
        except OSError as exc:
            report["unreadable"].append(filename)
            output(
                f"Could not read cached file {filename!r}: "
                f"{type(exc).__name__}: {exc}"
            )
            continue
        report["matched"] += 1
        if (
            str(row.get("size", "")) != actual_size
            or str(row.get("checksum", "")).lower() != actual_checksum
        ):
            row["size"] = actual_size
            row["checksum"] = actual_checksum
            report["updated"] += 1

    report["valid"] = not report["unreadable"]
    output(
        "Cache metadata scan: "
        f"entries={report['entries']} matched={report['matched']} "
        f"updated={report['updated']} missing={len(report['missing'])} "
        f"unsafe={len(report['unsafe'])} "
        f"unreadable={len(report['unreadable'])} "
        f"unlisted={len(report['unlisted'])} "
        f"ignored_nonpackage={len(report['ignored'])}"
    )
    if report["ignored"]:
        output(f"Ignored non-package cache files: {report['ignored']!r}")
    return report


def patch_manifest_ip(
    new_ip,
    manifest_file=MANIFEST_FILE,
    output=print,
    cache_dir=None,
):
    try:
        normalized_ip = str(ipaddress.IPv4Address(str(new_ip).strip()))
    except ipaddress.AddressValueError:
        output(f"Invalid IPv4 address: {new_ip!r}")
        return 2

    if not os.path.isfile(manifest_file):
        output(f"Missing {manifest_file}")
        return 1

    try:
        with open(manifest_file, encoding="utf-8") as handle:
            raw = handle.read()
        document = json.loads(raw)
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        output(f"Could not read valid manifest JSON: {type(exc).__name__}: {exc}")
        return 1

    old_ips = _manifest_ipv4_hosts(document)
    replace_ips = [value for value in old_ips if value != normalized_ip]
    patched = raw
    replacement_count = 0
    for old_ip in replace_ips:
        host_pattern = re.compile(
            rf"(?<![0-9.]){re.escape(old_ip)}(?![0-9.])"
        )
        patched, replacements = host_pattern.subn(normalized_ip, patched)
        if replacements:
            replacement_count += replacements
            output(f"Replaced {old_ip} -> {normalized_ip} ({replacements} occurrences)")

    try:
        patched_document = json.loads(patched)
    except json.JSONDecodeError as exc:
        output(f"Patched manifest failed JSON validation: {exc}")
        return 1

    cache_report = None
    if cache_dir is False:
        output("Cache metadata scan explicitly disabled.")
    else:
        if cache_dir is None:
            cache_dir = os.path.join(
                os.path.dirname(os.path.abspath(manifest_file)),
                "cache_files",
            )
        cache_report = reconcile_manifest_cache(
            patched_document,
            cache_dir,
            output,
        )
        if not cache_report["valid"]:
            output("Manifest was left unchanged because cache validation failed.")
            return 1
    if cache_report and cache_report["updated"]:
        patched = json.dumps(
            patched_document,
            ensure_ascii=True,
            separators=(",", ":"),
        )

    if not replacement_count:
        if normalized_ip in old_ips:
            output(f"Manifest already uses {normalized_ip}; IP unchanged.")
        else:
            output("No IPv4 URL hosts were found in the manifest; IP unchanged.")
    if patched == raw:
        output("Manifest IP and cache metadata already match; no changes needed.")
        return 0

    _atomic_write_text(manifest_file, patched, output)
    output(f"Updated {manifest_file}")
    return 0


def run(
    lan_ip,
    regenerate=False,
    force_onlineoptions=False,
    ip_only=False,
    output=print,
):
    oo_rc = generate_onlineoptions(
        output=output,
        force=force_onlineoptions or regenerate or not os.path.isfile(ONLINE_OPTIONS_FILE),
    )
    if oo_rc != 0:
        return oo_rc

    need_generate = regenerate or not os.path.isfile(MANIFEST_FILE)
    if need_generate:
        if ip_only:
            output(
                f"Missing {MANIFEST_FILE}; cannot use --ip-only without an existing manifest."
            )
            return 1
        document, rc = build_manifest_from_cache(lan_ip, output=output)
        if rc != 0:
            return rc
        return write_manifest(document, output=output)

    if ip_only:
        return patch_manifest_ip(lan_ip, output=output, cache_dir=False)
    return patch_manifest_ip(lan_ip, output=output)


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    regenerate = False
    force_onlineoptions = False
    ip_only = False
    filtered = []
    for arg in argv:
        if arg in ("--regenerate", "-r"):
            regenerate = True
        elif arg in ("--force-onlineoptions",):
            force_onlineoptions = True
        elif arg in ("--ip-only",):
            ip_only = True
        elif arg in ("-h", "--help"):
            print(
                "Usage: python patch_manifest_ip.py NEW_PC_LAN_IP [--regenerate] [--ip-only]\n"
                "Example: python patch_manifest_ip.py 192.168.0.42\n\n"
                "Generates local fixed_manifest.json from cache_files/ and\n"
                "onlineoptions from built-in defaults when missing.\n"
                "Use --regenerate to rebuild both from sources even if present.\n"
                "Use --ip-only to update an existing manifest IP without cache packs."
            )
            return 0
        else:
            filtered.append(arg)
    if len(filtered) != 1:
        print("Usage: python patch_manifest_ip.py NEW_PC_LAN_IP [--regenerate] [--ip-only]")
        print("Example: python patch_manifest_ip.py 192.168.0.42")
        return 2
    if ip_only and regenerate:
        print("Choose only one of --ip-only or --regenerate.")
        return 2
    return run(
        filtered[0],
        regenerate=regenerate,
        force_onlineoptions=force_onlineoptions,
        ip_only=ip_only,
    )


if __name__ == "__main__":
    sys.exit(main())
