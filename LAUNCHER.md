# Launcher design

## Why the `.bat` is tiny

Windows `cmd.exe` breaks when folder names contain parentheses (for example `New folder (3)` or `Program Files (x86)`).  
Inside `IF (...)` / `FOR (...)` blocks, a `)` in the path can close the block early. Commands then split into fragments such as `/d`, `ll`, or `not`.

So **all real launcher logic lives in PowerShell**, which handles those paths correctly.

## Files

| File | Role |
| --- | --- |
| `JPB Offline Server Launcher.bat` | Double-click entry only: `cd` to its own folder, run `launcher_main.ps1`. No game logic. |
| `launcher_main.ps1` | Menus, settings, manifest patch, BlueStacks optional sync, starts the Python server. |
| `launcher_ui.ps1` | Centered menu drawing / key input. |
| `ui_line.ps1` | Centered status lines. |
| `resolve_python.cmd` | Optional helper for older flows; `launcher_main.ps1` finds Python itself. |

## Rules for future changes

1. Do **not** put `IF (...)` / `FOR (...)` blocks with expanded folder paths back into the `.bat`.
2. Do **not** create `SUBST` drive letters for this launcher.
3. Keep the `.bat` as a wrapper; change behavior in `launcher_main.ps1`.
4. Test from a folder whose path has **spaces** and **parentheses** before shipping launcher edits.
