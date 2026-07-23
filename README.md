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
2. A **user-supplied**, **clean / legitimate** old **Android or iOS** client you are allowed to run — **no binary patching or other client patching is needed**
3. For Android emulator play: an emulator whose clock can stay aligned with the PC clock — **[BlueStacks](https://www.bluestacks.com/)** is **recommended** (see below)
4. **User-supplied** cache files when the client still needs to download assets from the emulator — use the matching platform caches (**Android** or **iOS**) in `cache_files/`, then generate the local manifest / onlineoptions with the launcher. If the client **already has** the needed cache files on the device, you may not need to re-serve a full cache pack from `cache_files/`
5. A way to **redirect** the game’s old online hostnames to your PC (see below) — still **without** modifying the client. On a **real Android or iOS device**, you can use **hostname / address routing** or **Technitium DNS + Tailscale** (personal mesh); on Android emulator / same LAN, **AdAway**-style hosts redirects are typical.

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

### Playing on a real Android device (Technitium DNS + Tailscale)

Use this when you want the **clean client on a physical Android phone/tablet** to talk to the emulator on your PC.  
[Tailscale](https://tailscale.com/) builds a **private mesh** between **your** devices. [Technitium DNS Server](https://technitium.com/dns/) on the PC answers the game’s old hostnames with your PC’s Tailscale IP — still **without** patching the APK.

This stays under **personal / private** use (your account, your devices). It is **not** a guide for public or community hosting.

**High-level idea**

1. PC runs this offline server emulator + Technitium DNS.  
2. Phone and PC join the **same Tailscale tailnet**.  
3. The phone uses Technitium (over Tailscale) as DNS so game hostnames resolve to the PC.  
4. The local manifest / `onlineoptions` are generated with the PC’s **Tailscale** IPv4 (not only your home Wi‑Fi LAN IP).

**1. Tailscale on PC and phone**

1. Install Tailscale on the Windows PC and on the Android device.  
2. Sign both into the **same** Tailscale account and make sure both are connected.  
3. On the PC, note the Tailscale IPv4 (usually `100.x.x.x`) from the Tailscale app or admin console.  
4. Confirm the phone can ping that Tailscale IP (Tailscale app / network tools).

**2. Technitium DNS on the PC**

1. Install **[Technitium DNS Server](https://technitium.com/dns/)** on the same PC that runs the emulator.  
2. Open the Technitium web console and ensure the DNS service is listening so Tailscale clients can reach it (typically bind/listen on the Tailscale interface or all interfaces — see Technitium’s settings).  
3. Allow inbound DNS (**UDP/TCP 53**) from Tailscale on the Windows firewall if needed.  
4. Create **local primary zones** (or equivalent local records) so these names resolve to the PC’s **Tailscale** IPv4, for example:

```text
d2x9ckrb1hxif.cloudfront.net   →  A  →  <PC Tailscale IPv4>
jp-4-9-0-pag.ludia.net         →  A  →  <PC Tailscale IPv4>
```

   One reliable pattern in Technitium is a **primary zone per hostname**, with an apex (`@`) **A** record pointing at the PC Tailscale IP.  
5. Your client may use other hostnames — check what **your** install queries and add matching local records the same way.

**3. Point the phone’s DNS at Technitium via Tailscale**

1. In the [Tailscale admin DNS settings](https://login.tailscale.com/admin/dns), add a **custom nameserver** set to the PC’s Tailscale IPv4 (where Technitium is listening).  
2. Enable **Override local DNS** (or the equivalent client option) so the Android Tailscale client actually uses that nameserver while Tailscale is connected.  
3. On the phone, keep Tailscale **connected** while playing.  
4. Optional check from the phone: resolve `jp-4-9-0-pag.ludia.net` / the CloudFront hostname and confirm they return the PC Tailscale IP.

**4. Generate the manifest for Tailscale**

1. Put your caches in `cache_files/` as usual.  
2. In the launcher, **[2] Generate / Patch Manifest** (or `python patch_manifest_ip.py <PC-TAILSCALE-IP>`).  
3. When asked for the PC IPv4, enter the **Tailscale** address (`100.x.x.x`), not only your home LAN IP, so asset URLs are reachable from the phone over Tailscale.  
4. Start the emulator with **[1] Play**. Allow the game / HTTP(S) ports on the Windows firewall for Tailscale if Windows prompts you.

**5. Install and run the clean client on the phone**

1. Install your **own lawful** clean Android client (no APK binary patch required).  
2. With Tailscale connected and DNS overriding to Technitium, launch the game.  
3. It should reach the emulator on your PC the same way an emulator client does via AdAway — the redirect is DNS + private mesh instead of a local hosts VPN app.

**Notes / troubleshooting**

- **Same Wi‑Fi only?** AdAway (or similar) on the phone pointing at your **LAN** IP is often simpler; use Tailscale + Technitium when you want a stable path that is not tied to home Wi‑Fi routing alone.  
- **Clock / timers:** on a real device, keep **Automatic date & time** enabled and keep the PC clock accurate. Large skew between phone and PC can still cause timer oddities (BlueStacks ADB clock sync does not apply to a physical phone).  
- **DNS not overriding:** if hostnames still resolve to public/CDN addresses, confirm Tailscale Override DNS is on, Technitium has the local A records, and the phone is using Tailscale’s DNS path.  
- **Assets fail but login seems to work (or the reverse):** re-check that the manifest was generated with the **same** Tailscale IP the phone can reach, and that Technitium points the game hostnames at that same IP.  
- Reminder: this is for **your** PC and **your** device on **your** tailnet — not a public community server.

### Playing on iOS

The emulator can also be used with a **user-supplied**, **clean / legitimate** old **iOS** client. Same personal / local rules as Android: **no IPA redistribution** from this repo, and **no client binary patching** is required.

**Routing**

Point the game’s old online hostnames at your PC with either:

- **Hostname / address routing** on your network (or equivalent local DNS / redirect you already use), or  
- The same **Technitium DNS + Tailscale** personal-mesh setup described above for real devices (install Tailscale on the iPhone/iPad, override DNS to Technitium, generate the manifest with the PC’s **Tailscale** IPv4)

**Caches**

iOS needs **iOS** cache assets (not the Android pack), unless the install already has what it needs:

- Put **user-supplied iOS** cache files in `cache_files/` and generate / patch the manifest as usual, **or**  
- If the iOS client **already has** the cache files on the device, you can play with routing alone for login / save traffic without re-adding a full iOS cache pack to the PC

Use only caches and a client you are allowed to use. This repo still does **not** provide IPAs, iOS caches, or download links.

---



## Quick start (code only)

1. Clone this GitHub repository.
2. Put **your own** cache files into the `cache_files/` folder (do not commit them).
3. Start `JPB Offline Server Launcher.bat` (it runs `launcher_main.ps1` from the same folder — see [`LAUNCHER.md`](LAUNCHER.md)).
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
