# Main launcher logic for JPB Offline Server.
# Invoked by "JPB Offline Server Launcher.bat" so CMD never parses paths that contain ().
# This script always runs from its own folder (any drive / spaces / parentheses).

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $Root
$Host.UI.RawUI.WindowTitle = "Unofficial Jurassic Park Builder - Offline Server"

$ServerScript = Join-Path $Root "JPB_Offline_Server_Emulator.py"
$SettingsFile = Join-Path $Root "launcher_settings.ini"
$PatchScript = Join-Path $Root "patch_manifest_ip.py"
$UiMenu = Join-Path $Root "launcher_ui.ps1"
$UiLine = Join-Path $Root "ui_line.ps1"

$script:BucksMode = "legit"
$script:CustomAmount = "5"
$script:CustomFrequency = "daily"
$script:PythonExe = $null

function Write-UiLine {
  param(
    [ValidateSet("Yellow", "Red", "Blank")]
    [string]$Mode,
    [string]$Text = ""
  )
  & $UiLine -Mode $Mode -Text $Text
}

function Write-Banner {
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Red -Text "==============================================="
  Write-UiLine -Mode Yellow -Text "UNOFFICIAL"
  Write-UiLine -Mode Yellow -Text "JURASSIC PARK BUILDER"
  Write-UiLine -Mode Yellow -Text "Offline Server Emulator"
  Write-UiLine -Mode Red -Text "==============================================="
}

function Get-BucksDescription {
  switch ($script:BucksMode) {
    "legit" { return "Normal - 5 each day, plus 25 every 7 days" }
    "sandbox" { return "Sandbox - a huge one-time gift per save" }
    default {
      if ($script:CustomFrequency -eq "daily") {
        return "Custom - $($script:CustomAmount) every 24 hours"
      }
      return "Custom - $($script:CustomAmount) on each game login"
    }
  }
}

function Save-Settings {
  @(
    "BUCKS_MODE=$($script:BucksMode)"
    "CUSTOM_AMOUNT=$($script:CustomAmount)"
    "CUSTOM_FREQUENCY=$($script:CustomFrequency)"
  ) | Set-Content -LiteralPath $SettingsFile -Encoding ASCII
}

function Load-Settings {
  $script:BucksMode = "legit"
  $script:CustomAmount = "5"
  $script:CustomFrequency = "daily"
  if (-not (Test-Path -LiteralPath $SettingsFile)) {
    Save-Settings
    return
  }
  foreach ($line in Get-Content -LiteralPath $SettingsFile -ErrorAction SilentlyContinue) {
    if ($line -match '^\s*BUCKS_MODE\s*=\s*(.+)\s*$') {
      $v = $Matches[1].Trim()
      if ($v -in @("legit", "sandbox", "custom")) { $script:BucksMode = $v }
    }
    elseif ($line -match '^\s*CUSTOM_AMOUNT\s*=\s*(.+)\s*$') {
      $v = $Matches[1].Trim()
      if ($v -match '^\d{1,10}$') { $script:CustomAmount = $v }
    }
    elseif ($line -match '^\s*CUSTOM_FREQUENCY\s*=\s*(.+)\s*$') {
      $v = $Matches[1].Trim()
      if ($v -in @("daily", "per_login")) { $script:CustomFrequency = $v }
    }
  }
}

function Test-RequiredLauncherFiles {
  $required = @(
    "launcher_main.ps1",
    "launcher_ui.ps1",
    "ui_line.ps1",
    "JPB_Offline_Server_Emulator.py",
    "patch_manifest_ip.py"
  )
  $missing = @($required | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Root $_)) })
  if ($missing.Count -eq 0) { return $true }
  Write-Host ""
  Write-Host "Missing launcher files next to this .bat:"
  foreach ($name in $missing) { Write-Host "  $name" }
  Write-Host ""
  Write-Host "Download the full project folder from GitHub (not only the .bat file)."
  Write-Host ""
  Read-Host "Press Enter to close"
  return $false
}

function Resolve-PythonExe {
  $candidates = New-Object System.Collections.Generic.List[string]
  $candidates.Add((Join-Path $Root ".venv\Scripts\python.exe")) | Out-Null
  $local = $env:LOCALAPPDATA
  if ($local) {
    @(
      "Python\pythoncore-3.14-64\python.exe",
      "Programs\Python\Python314\python.exe",
      "Programs\Python\Python313\python.exe",
      "Programs\Python\Python312\python.exe"
    ) | ForEach-Object { $candidates.Add((Join-Path $local $_)) | Out-Null }
  }
  foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) {
      if (Test-PythonVersion $path) {
        $script:PythonExe = $path
        return $true
      }
    }
  }
  $where = & where.exe python.exe 2>$null
  foreach ($path in @($where)) {
    if (-not $path) { continue }
    if ($path -like "*\WindowsApps\*") { continue }
    if ((Test-Path -LiteralPath $path) -and (Test-PythonVersion $path)) {
      $script:PythonExe = $path
      return $true
    }
  }
  try {
    $pyOut = & py -3 -c "import sys; print(sys.executable)" 2>$null
    if ($pyOut -and (Test-Path -LiteralPath $pyOut) -and (Test-PythonVersion $pyOut)) {
      $script:PythonExe = $pyOut
      return $true
    }
  } catch { }

  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Python was not found on this PC."
  Write-UiLine -Mode Yellow -Text "Install Python 3 from python.org, then try again."
  return $false
}

function Test-PythonVersion([string]$Exe) {
  try {
    & $Exe -c "import sys; raise SystemExit(0 if sys.version_info[0]==3 and sys.version_info[1]>=10 else 1)" | Out-Null
    return ($LASTEXITCODE -eq 0)
  } catch {
    return $false
  }
}

function Test-AmountValue([string]$Value) {
  try {
    $n = [int64]$Value
    return ($n -ge 1 -and $n -le 2000000000)
  } catch {
    return $false
  }
}

function Get-LanIp {
  try {
    $ip = Get-NetIPConfiguration |
      Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq "Up" } |
      Select-Object -First 1 -ExpandProperty IPv4Address |
      Select-Object -First 1 -ExpandProperty IPAddress
    if ($ip) { return [string]$ip }
  } catch { }
  return $null
}

function Stop-OldServer {
  Get-CimInstance Win32_Process -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "python*.exe" -and $_.CommandLine -like "*JPB_Offline_Server_Emulator.py*" } |
    ForEach-Object {
      Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
}

function Ensure-ConnectionFiles([string]$LanIp) {
  if (-not $LanIp) {
    Clear-Host
    Write-Banner
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Could not detect your PC's network address."
    Write-UiLine -Mode Yellow -Text "Use menu [2] First-time setup and type your IPv4 manually,"
    Write-UiLine -Mode Yellow -Text "or connect to Wi-Fi / Ethernet and try again."
    return $false
  }
  $cacheDir = Join-Path $Root "cache_files"
  if (-not (Test-Path -LiteralPath $cacheDir)) {
    Clear-Host
    Write-Banner
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Missing cache_files folder."
    Write-UiLine -Mode Yellow -Text "Put your own cache packs in cache_files, then try again."
    return $false
  }
  $havePacks = @(Get-ChildItem -LiteralPath $cacheDir -File -ErrorAction SilentlyContinue |
      Where-Object { $_.Extension -match '^\.(dab|dhr|dsb)$' }).Count -gt 0
  $patchExtra = @()
  if (-not $havePacks) {
    $manifest = Join-Path $Root "fixed_manifest.json"
    $online = Join-Path $Root "onlineoptions"
    if ((Test-Path -LiteralPath $manifest) -and (Test-Path -LiteralPath $online)) {
      Write-UiLine -Mode Blank
      Write-UiLine -Mode Yellow -Text "No cache packs found. Using your existing connection files."
      $patchExtra = @("--ip-only")
    } else {
      Clear-Host
      Write-Banner
      Write-UiLine -Mode Blank
      Write-UiLine -Mode Yellow -Text "No game cache packs were found."
      Write-UiLine -Mode Yellow -Text "Put your .dab / .dhr / .dsb files in the cache_files folder,"
      Write-UiLine -Mode Yellow -Text "then use [2] First-time setup, or press [1] again."
      return $false
    }
  }
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Checking connection files for $LanIp ..."
  & $script:PythonExe $PatchScript $LanIp @patchExtra
  if ($LASTEXITCODE -ne 0) {
    Clear-Host
    Write-Banner
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Could not create connection files."
    Write-UiLine -Mode Yellow -Text "Make sure cache_files has your .dab / .dhr / .dsb packs,"
    Write-UiLine -Mode Yellow -Text "then try [2] First-time setup."
    return $false
  }
  return $true
}

function Find-BlueStacksAdb {
  $cands = @(
    (Join-Path ${env:ProgramFiles} "BlueStacks_nxt\HD-Adb.exe"),
    (Join-Path ${env:ProgramFiles} "BlueStacks\HD-Adb.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "BlueStacks\HD-Adb.exe")
  )
  foreach ($p in $cands) {
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  }
  return $null
}

function Get-BlueStacksSerial([string]$AdbExe) {
  try { & $AdbExe connect "127.0.0.1:5555" | Out-Null } catch { }
  $preferred = @("emulator-5554", "127.0.0.1:5555")
  $devices = @()
  $lines = & $AdbExe devices 2>$null
  foreach ($line in $lines) {
    if ($line -match '^(\S+)\s+device$') { $devices += $Matches[1] }
  }
  foreach ($p in $preferred) {
    if ($devices -contains $p) { return $p }
  }
  if ($devices.Count -gt 0) { return $devices[0] }
  return $null
}

function Show-MenuChoice([string]$Menu) {
  # Start-Process -ArgumentList arrays do NOT quote paths with spaces, so -File
  # would become C:\...\Jurassic and fail. Build one properly quoted argument string.
  $desc = Get-BucksDescription
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = (Get-Command powershell.exe).Source
  $psi.WorkingDirectory = $Root
  $psi.UseShellExecute = $false
  $fileArg = $UiMenu.Replace('"', '\"')
  $descArg = $desc.Replace('"', '\"')
  $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$fileArg`" -Menu $Menu -BucksDescription `"$descArg`""
  $p = [System.Diagnostics.Process]::Start($psi)
  $p.WaitForExit()
  return [int]$p.ExitCode
}

function Invoke-CustomBucks {
  if (-not (Resolve-PythonExe)) {
    Read-Host "Press Enter to continue"
    return
  }
  Write-UiLine -Mode Blank
  $inputAmount = Read-Host "How many bucks? (1-2000000000)"
  if (-not (Test-AmountValue $inputAmount)) {
    Write-UiLine -Mode Yellow -Text "Please enter numbers only, from 1 to 2000000000."
    Read-Host "Press Enter to continue"
    Invoke-CustomBucks
    return
  }
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "How often should they be gifted?"
  Write-UiLine -Mode Yellow -Text "[1] Every time the game logs into the server"
  Write-UiLine -Mode Yellow -Text "[2] Once every 24 hours"
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Press 1 or 2:"
  while ($true) {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    if ($key.Character -eq "1") {
      $script:CustomFrequency = "per_login"
      break
    }
    if ($key.Character -eq "2") {
      $script:CustomFrequency = "daily"
      break
    }
  }
  $script:CustomAmount = $inputAmount
  $script:BucksMode = "custom"
  Save-Settings
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Custom bucks settings saved."
  Write-UiLine -Mode Blank
  Read-Host "Press Enter to continue"
}

function Invoke-BucksOptions {
  while ($true) {
    $choice = Show-MenuChoice "Bucks"
    switch ($choice) {
      4 { return }
      3 { Invoke-CustomBucks; return }
      2 {
        $script:BucksMode = "sandbox"
        Save-Settings
        Write-UiLine -Mode Blank
        Write-UiLine -Mode Yellow -Text "Sandbox selected. The one-time gift is saved with your game."
        Write-UiLine -Mode Blank
        Read-Host "Press Enter to continue"
        return
      }
      1 {
        $script:BucksMode = "legit"
        Save-Settings
        Write-UiLine -Mode Blank
        Write-UiLine -Mode Yellow -Text "Normal play selected."
        Write-UiLine -Mode Blank
        Read-Host "Press Enter to continue"
        return
      }
    }
  }
}

function Invoke-PatchManifest {
  Clear-Host
  Write-Banner
  if (-not (Resolve-PythonExe)) {
    Read-Host "Press Enter to continue"
    return
  }
  $lanIp = Get-LanIp
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "This step tells the game how to reach THIS PC."
  Write-UiLine -Mode Yellow -Text "Put your cache files in the cache_files folder first."
  Write-UiLine -Mode Blank
  if ($lanIp) {
    Write-UiLine -Mode Yellow -Text "Detected PC address: $lanIp"
    Write-UiLine -Mode Yellow -Text "Press Enter to use that, or type a different IPv4."
  } else {
    Write-UiLine -Mode Yellow -Text "Could not detect your PC address automatically."
    Write-UiLine -Mode Yellow -Text "Find it with ipconfig (IPv4 Address), then type it below."
  }
  Write-UiLine -Mode Blank
  $manifestIp = Read-Host "PC IPv4 address"
  if ([string]::IsNullOrWhiteSpace($manifestIp) -and $lanIp) { $manifestIp = $lanIp }
  if ([string]::IsNullOrWhiteSpace($manifestIp)) {
    Write-UiLine -Mode Yellow -Text "No address entered. Returning to the menu."
    Read-Host "Press Enter to continue"
    return
  }
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Creating local connection files..."
  Write-UiLine -Mode Blank
  & $script:PythonExe $PatchScript $manifestIp.Trim()
  $patchExit = $LASTEXITCODE
  Write-UiLine -Mode Blank
  if ($patchExit -eq 0) {
    Write-UiLine -Mode Yellow -Text "Setup finished. You can now choose [1] Start playing."
  } else {
    Write-UiLine -Mode Yellow -Text "Setup failed (error $patchExit)."
    Write-UiLine -Mode Yellow -Text "Check that cache_files has your packs, then try again."
  }
  Write-UiLine -Mode Blank
  Read-Host "Press Enter to continue"
}

function Start-OfflineServer {
  Clear-Host
  Write-Banner
  if (-not (Resolve-PythonExe)) {
    Read-Host "Press Enter to continue"
    return
  }
  if ($script:BucksMode -eq "custom" -and -not (Test-AmountValue $script:CustomAmount)) {
    Write-UiLine -Mode Yellow -Text "Saved custom amount was invalid. Switching back to Normal play."
    $script:BucksMode = "legit"
    $script:CustomAmount = "5"
    $script:CustomFrequency = "daily"
    Save-Settings
  }

  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Preparing to start..."
  Write-UiLine -Mode Yellow -Text "Stopping any old server still running..."
  Stop-OldServer

  $lanIp = Get-LanIp
  if ($lanIp) {
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Your PC address: $lanIp"
    Write-UiLine -Mode Yellow -Text "Game should connect to this PC on your home network."
  }

  if (-not (Ensure-ConnectionFiles $lanIp)) {
    Write-UiLine -Mode Blank
    Read-Host "Press Enter to continue"
    return
  }

  Write-UiLine -Mode Yellow -Text ("Bucks rewards: " + (Get-BucksDescription))

  $adbExe = $null
  $adbSerial = $null
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "If you use BlueStacks, answer Y so game timers stay in sync."
  Write-UiLine -Mode Yellow -Text "Answer N if you are not using BlueStacks."
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Use BlueStacks clock sync? [Y/N]:"
  $bs = Read-Host
  if ($bs -match '^[Yy](es)?$') {
    $adbExe = Find-BlueStacksAdb
    if (-not $adbExe) {
      Write-UiLine -Mode Yellow -Text "BlueStacks was not found. Starting without clock sync."
    } else {
      $adbSerial = Get-BlueStacksSerial $adbExe
      if (-not $adbSerial) {
        Write-UiLine -Mode Yellow -Text "No BlueStacks device found. Starting without clock sync."
        $adbExe = $null
      } else {
        Write-UiLine -Mode Yellow -Text "BlueStacks connected. Clock sync is on."
      }
    }
  } else {
    Write-UiLine -Mode Yellow -Text "Starting without BlueStacks sync."
  }

  $mailPolicy = "legit"
  $mailAmount = "5"
  if ($script:BucksMode -eq "sandbox") {
    $mailPolicy = "sandbox_once"
    $mailAmount = "99999999"
  } elseif ($script:BucksMode -eq "custom") {
    if ($script:CustomFrequency -eq "daily") { $mailPolicy = "daily" }
    elseif ($script:CustomFrequency -eq "per_login") { $mailPolicy = "per_login" }
    if ($script:CustomAmount) { $mailAmount = $script:CustomAmount }
  }

  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Starting the offline server..."
  Write-UiLine -Mode Yellow -Text "Leave this window open while you play."
  Write-UiLine -Mode Yellow -Text "Press Ctrl+C here when you want to stop."
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Live server log below (ports, logins, saves):"
  Write-UiLine -Mode Blank
  Write-Host ""

  $serverArgs = @(
    "-u", $ServerScript,
    "--host", "0.0.0.0",
    "--game-services-mode", "generic",
    "--composite-profile", "savegame",
    "--mail-mode", "hardcash",
    "--hardcash-gift-policy", $mailPolicy,
    "--hardcash-gift-amount", $mailAmount,
    "--friend-mode", "random_user_stub",
    "--post-login-push", "online_options"
  )
  if ($adbExe -and $adbSerial) {
    $serverArgs += @(
      "--adb-logcat",
      "--sync-adb-clock",
      "--adb-clock-max-drift-seconds", "5",
      "--adb-clock-sync-interval-seconds", "60",
      "--adb-timezone", "auto",
      "--adb-path", $adbExe,
      "--adb-serial", $adbSerial
    )
  }

  try {
    & $script:PythonExe @serverArgs
    $serverExit = $LASTEXITCODE
  } catch {
    $serverExit = 1
  }

  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Server stopped (code $serverExit)."
  Write-UiLine -Mode Blank
  Read-Host "Press Enter to continue"
}

# ---- entry ----
if (-not (Test-RequiredLauncherFiles)) { exit 1 }
Load-Settings

while ($true) {
  $choice = Show-MenuChoice "Main"
  switch ($choice) {
    4 { exit 0 }
    3 { Invoke-BucksOptions }
    2 { Invoke-PatchManifest }
    1 { Start-OfflineServer }
  }
}
