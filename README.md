# Unofficial Offline Server Emulator (Preservation Project)

**Free · unofficial · non-commercial · not affiliated with Ludia, Universal, or any rights holder.**  
**Hosted on GitHub.**

This GitHub repository provides **server emulator source code** so people who already have the old mobile game client can experiment with **local / private offline play** after the official service was shut down and delisted.

It is a **fan preservation / interoperability research** project.  
It is **not** an official product, sequel, remaster, or authorized private server.  
It is also **independent of** other fan remakes, revivals, and local-server emulator projects — including any that have drawn rights-holder enforcement. This repo is not a continuation of, fork of, or partner to those efforts.

---



## What this project is

- A **Python offline / local server emulator** for the discontinued client protocol
- A small launcher to run that emulator on your own machine
- Tools to point a **user-supplied** asset manifest at your own PC / LAN
- Designed to work with **clean, legitimate copies** of the game — **no APK / client binary patches** (or other client patches) are required



## What this project is not

- **Not affiliated with, endorsed by, or sponsored by** Ludia, Universal, or any trademark owner
- **Not affiliated with, and never was affiliated with**, any past or present fan remake, revival, or third-party server project for this game — including projects that have drawn rights-holder enforcement — nor other local / private server emulator projects
- **Not** a redistribution of the game
- **Not** a source of APKs, IPAs, OBB files, cache packs, textures, audio, or other game assets
- **Not** a replacement storefront, public online service, or cloud-hosted “community server”
- **Not** permission to pirate the client or share copyrighted files

If you do not already have a lawful copy of the client / caches, this project is not for obtaining them.

---



## Local use only — no cloud / community servers

This project is intended for **personal, local / LAN offline use** on your own machine (or a machine you control on your home network).

This project is **against**, and does **not** condone:

- Modifying this repository (or forks of it) to host the emulator in the **cloud** or on a public VPS
- Turning it into a **public or “community” multiplayer server** for other people to connect to over the internet
- Operating it as a substitute for the shut-down official online service for a wider audience

Pull requests, issues, or documentation that push cloud hosting, or shared online “revival” servers for this purpose will be rejected.  
If you fork the code, do not present cloud / community hosting as something this project supports or endorses.

---



## No game files are provided

This repository intentionally ships **code and documentation only**.


| Included                            | Not included                                 |
| ----------------------------------- | -------------------------------------------- |
| Server emulator source              | APK / IPA / OBB                              |
| Launcher scripts                    | Cache packs (`.dab` / `.dhr` / `.dsb`, etc.) |
| Manifest helper scripts             | Official CDN dumps                           |
| Empty folders for *your* local data | Piracy links or mirrors                      |


You must supply any client and cache files yourself from a source you are allowed to use.  
Do **not** open issues asking for APKs, caches, or download links — they will be closed.

Typical local layout after you add your own files:

```text
./                              ← this repo (code only)
cache_files/                    ← folder is in git; YOUR cache files inside are ignored
online_options_defaults.py      ← built-in defaults used to synthesize onlineoptions
fixed_manifest.json             ← generated locally (gitignored)
onlineoptions                   ← generated locally (gitignored)
guest_saves/                    ← folder is in git; YOUR saves inside are ignored
logs/                           ← folder is in git; log files inside are ignored
```

---



## Why this exists

The official online service for this old mobile title was **shut down and delisted**.  
Official multiplayer / online progression is gone. This project exists so that:

1. People who still have the old client can study and run a **local** emulator
2. Save / login / asset-serving behavior can be researched for **preservation and interoperability**
3. The discontinued protocol can be **documented** for preservation — **without redistributing the game**

Popularity of a fan project does not make it official.  
Preservation intent does not grant a license from the rights holders.

---



## Non-commercial policy

This project is **free**, and the license **strictly prohibits** selling or monetizing it (including modified copies).

- No paid accounts
- No “premium” unlock store run by this project
- No official merchandise or paid client redistributions from this repo
- No selling, paywalling, or other monetization of this code or forks of it
- No cloud-hosted or public community servers built from this project’s goals or branding

Forks and pull requests are welcome **only if they never include official game files**, stay **non-commercial**, keep **game assets out of git**, and do **not** turn this into a public / cloud community-server project.

---



## Trademark / branding notice

Names and marks such as “Jurassic Park”, “Jurassic Park Builder”, Ludia, and Universal are property of their respective owners.

They appear here only to identify the **discontinued game this emulator is compatible with**.  
This project does **not** claim those marks and does **not** imply endorsement.

---



## Requirements (high level)

1. **Python 3** on Windows (or adapt the launcher for your OS)
2. A **user-supplied**, **clean / legitimate** old Android client you are allowed to run — **no binary patching or other client patching is needed**
3. An Android emulator whose clock can stay aligned with the PC clock — **[BlueStacks](https://www.bluestacks.com/)** is **recommended** (see below)
4. **User-supplied** cache files in `cache_files/`, then generate the local manifest / onlineoptions with the launcher
5. A way to **redirect** the game’s old online hostnames to your PC’s LAN IP (see below) — still **without** modifying the APK

This repo does not teach or provide illegal client acquisition.

### Android emulator and clock sync (important)

Game timers (buildings, events, cooldowns, and similar) depend on time matching between the **server (your PC)** and the **client (the emulator)**.  
If the emulator clock drifts ahead or behind the PC clock, you can get **timer-related bugs**, stuck timers, or odd offline/online behavior.

- **Recommended:** BlueStacks (or another emulator that can keep its time the same as the PC)
- When you choose **[1] Play** in `JPB Offline Server Launcher.bat`, you get a prompt:  
  `Use BlueStacks ADB for logcat and clock sync? [Y/N]`
- Answer **Y** (recommended) so the launcher can auto-synchronize the BlueStacks emulator clock with the PC clock
- Answer **N** only if you are not using BlueStacks / ADB, or you knowingly skip sync (timer issues are more likely if clocks diverge)

### Pointing a clean client at your local emulator

You do **not** need to binary-patch the APK. On Android (device or emulator), a common approach is a local DNS / hosts redirect with an open-source app such as **[AdAway](https://adaway.org/)** (or any equivalent hosts tool you already use):

1. Note your PC’s LAN IPv4 (launcher detection and/or `ipconfig`).
2. In AdAway (or similar), add **redirect / hosts** rules that map the game’s old service hostnames to that IP.
3. Enable the hosts file / local VPN mode as required by your tool, then start this emulator and the game.

**Example hostnames** often used for local redirect (point each to your PC LAN IP):

```text
d2x9ckrb1hxif.cloudfront.net
jp-4-9-0-pag.ludia.net
```

Your client build may contact additional or different hostnames. Prefer confirming what **your** install actually reaches (AdAway request log, emulator network log, etc.) and redirect those as well. Do not assume one fixed list covers every dump or version.

---



## Quick start (code only)

1. Clone this GitHub repository.
2. Put **your own** cache files into the `cache_files/` folder (do not commit them).
3. Start `JPB Offline Server Launcher.bat`.
4. Press **[2] Generate / Patch Manifest** to create local `fixed_manifest.json` and `onlineoptions` (these are generated on your machine and are **not** shipped in the repo).
5. When prompted for the PC IPv4 address:
  - The launcher may show a **detected** LAN IP — you can accept that, **or**
  - Double-check it yourself with `ipconfig` in Command Prompt (look for your active adapter’s **IPv4 Address**, often under Wi‑Fi or Ethernet).
  - Enter that IP so the manifest URLs point at **your** PC.
6. Return to the menu and choose **[1] Play** to start the server.
7. When asked **Use BlueStacks ADB for logcat and clock sync? [Y/N]**, answer **Y** if you are using BlueStacks (recommended) so the emulator clock stays synced with the PC. Answer **N** only if you skip that sync on purpose.
8. Redirect the game’s old hostnames to your PC LAN IP (for example with **AdAway** — see **Pointing a clean client at your local emulator** above).  
   Use a **clean, legitimate** copy of the game — this server emulator does **not** require APK binary patches or any other client-side patch.

Optional: `python patch_manifest_ip.py YOUR.LAN.IP` (add `--regenerate` after changing caches).

Do not open pull requests that add copyrighted game binaries.

---

## License

The **original code and documentation in this repository** are provided under a **non-commercial** license — see [`LICENSE`](LICENSE).

- Free to use, copy, modify, and share for personal / non-commercial purposes  
- **Selling or monetizing this project, or modified / derived copies, is strictly prohibited**

That license covers **this project’s source only**. It does **not** license the game, APKs, caches, trademarks, or any other rights-holder content. You must supply any client/cache files yourself from a source you are allowed to use.

---



## Repository hygiene (please follow)

**Never commit:**

- Anything **inside** `cache_files/`, `guest_saves/`, or `logs/` (the empty folders themselves stay in the repo via `.gitkeep`)
- Generated `fixed_manifest.json` / `onlineoptions` (machine-local)
- APKs, IPAs, OBBs, `.dab` / `.dhr` / `.dsb` packs
- Captured account tokens, personal save dumps you don’t intend to share

**Do keep local only (never push):**

- Your caches, saves, logs, generated manifest/options, and any personal config

---



## Forks, pull requests, and issues

**Forks and pull requests are allowed**, with one hard rule:

> **Do not add, commit, or distribute official game files** — no APKs, IPAs, OBBs, cache packs (`.dab` / `.dhr` / `.dsb`, etc.), CDN dumps, or other copyrighted client assets.

Allowed examples:

- Bug fixes in the emulator / launcher  
- Documentation improvements  
- Helper scripts that build manifests from **the user’s own** local files  
- Protocol notes that do **not** include ripped assets

Not allowed in forks or pull requests:

- Official or ripped game binaries and caches  
- Links to piracy sources  
- Paid / premium access features built around someone else’s game  
- Changes aimed at cloud hosting or public / community online servers (this project does not condone that use)



### Bugs and support

If you hit a bug, crash, or setup problem:

1. **Open a GitHub Issue** on this repository  
2. Describe what you did, what you expected, and what happened  
3. Include logs when possible (never paste account tokens or personal save dumps you don’t mean to share)

Issues asking for APKs, caches, or download links will be closed.

---



## Rights holders — takedown via GitHub only

This project is shared in good faith for **interop research and personal offline preservation** of a **discontinued** service.  
It is intended to contain **server code only** — **no game APKs, caches, or other copyrighted game assets**.

**If you are a rights holder and want this project removed:**

- Please use **GitHub’s official DMCA process** (see GitHub’s DMCA takedown policy and notice form):  
  https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy  
  https://github.com/contact/dmca  
- You do **not** need to email the maintainer personally.  
- The maintainer **already agrees in advance** to comply with a valid GitHub removal of this repository.

**Maintainer commitment if GitHub removes this repository:**

1. The removal will be accepted without dispute theater.  
2. This project will **not** be re-uploaded by the maintainer to GitHub or as a public mirror.  
3. No alternate public hosting will be stood up by the maintainer to evade that removal.

Fork maintainers: if the upstream repository is removed, please remove official game files from your fork if any were added by mistake, and do not turn forks into asset mirrors.

See also [`SECURITY.md`](SECURITY.md).

---



## Disclaimer

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND.  
USE AT YOUR OWN RISK.

- You are responsible for complying with laws in your country.
- You are responsible for how you obtain and use any client or cache files.
- The maintainers are not responsible for bans, data loss, emulator issues, or third-party claims.
- Nothing in this README is a license from Ludia, Universal, or any other rights holder.
- Nothing in this README is legal advice.

---



## Credits

Built for personal offline use and preservation research after the official service ended.

**Unofficial. Free. Local-only. Hosted on GitHub. No game files included. Not affiliated with rights holders or other fan remake / server projects. Against cloud / community-server hosting. Forks/PRs OK without official assets — bugs → GitHub Issues.**
