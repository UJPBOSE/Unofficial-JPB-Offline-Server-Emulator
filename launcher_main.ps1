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
    [ValidateSet("Yellow", "Red", "Green", "Blank")]
    [string]$Mode,
    [string]$Text = ""
  )
  & $UiLine -Mode $Mode -Text $Text
}

function Write-StatusLine {
  param(
    [bool]$Ok,
    [string]$Label,
    [string]$Detail
  )
  $mark = if ($Ok) { "[OK]" } else { "[!!]" }
  $mode = if ($Ok) { "Green" } else { "Yellow" }
  Write-UiLine -Mode $Mode -Text ("$mark $Label - $Detail")
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

function Find-PythonExeQuiet {
  $candidates = New-Object System.Collections.Generic.List[string]
  $candidates.Add((Join-Path $Root ".venv\Scripts\python.exe")) | Out-Null
  $local = $env:LOCALAPPDATA
  if ($local) {
    @(
      "Python\pythoncore-3.14-64\python.exe",
      "Programs\Python\Python314\python.exe",
      "Programs\Python\Python313\python.exe",
      "Programs\Python\Python312\python.exe",
      "Programs\Python\Python311\python.exe",
      "Programs\Python\Python310\python.exe"
    ) | ForEach-Object { $candidates.Add((Join-Path $local $_)) | Out-Null }
  }
  foreach ($path in $candidates) {
    if (Test-Path -LiteralPath $path) {
      if (Test-PythonVersion $path) {
        return $path
      }
    }
  }
  $where = & where.exe python.exe 2>$null
  foreach ($path in @($where)) {
    if (-not $path) { continue }
    if ($path -like "*\WindowsApps\*") { continue }
    if ((Test-Path -LiteralPath $path) -and (Test-PythonVersion $path)) {
      return $path
    }
  }
  try {
    $pyOut = & py -3 -c "import sys; print(sys.executable)" 2>$null
    if ($pyOut -and (Test-Path -LiteralPath $pyOut) -and (Test-PythonVersion $pyOut)) {
      return $pyOut
    }
  } catch { }
  return $null
}

function Offer-PythonDownload {
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Python 3.10+ is required for this offline server."
  Write-UiLine -Mode Yellow -Text "Open the Python download page in your browser? [Y/N]"
  $ans = Read-Host
  if ($ans -match '^[Yy](es)?$') {
    try {
      Start-Process "https://www.python.org/downloads/"
      Write-UiLine -Mode Blank
      Write-UiLine -Mode Yellow -Text "Install Python, tick Add python.exe to PATH, then reopen this launcher."
    } catch {
      Write-UiLine -Mode Yellow -Text "Could not open the browser. Go to https://www.python.org/downloads/"
    }
  } else {
    Write-UiLine -Mode Yellow -Text "Install Python 3 from https://www.python.org/downloads/ then try again."
  }
}

function Resolve-PythonExe {
  $found = Find-PythonExeQuiet
  if ($found) {
    $script:PythonExe = $found
    return $true
  }
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Python was not found on this PC."
  Offer-PythonDownload
  return $false
}

function Test-IPv4Address([string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  return [bool]($Value -match '^(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)$')
}

function Get-CachePackInfo {
  $cacheDir = Join-Path $Root "cache_files"
  $result = [ordered]@{
    DirExists = $false
    PackCount = 0
    Dab = 0
    Dhr = 0
    Dsb = 0
  }
  if (-not (Test-Path -LiteralPath $cacheDir)) { return $result }
  $result.DirExists = $true
  $files = @(Get-ChildItem -LiteralPath $cacheDir -File -ErrorAction SilentlyContinue)
  foreach ($f in $files) {
    switch ($f.Extension.ToLowerInvariant()) {
      ".dab" { $result.Dab++; $result.PackCount++ }
      ".dhr" { $result.Dhr++; $result.PackCount++ }
      ".dsb" { $result.Dsb++; $result.PackCount++ }
    }
  }
  return $result
}

function Get-SetupStatus {
  $py = Find-PythonExeQuiet
  $cache = Get-CachePackInfo
  $manifestPath = Join-Path $Root "fixed_manifest.json"
  $onlinePath = Join-Path $Root "onlineoptions"
  $lanIp = Get-LanIp
  $manifestOk = Test-Path -LiteralPath $manifestPath
  $onlineOk = Test-Path -LiteralPath $onlinePath
  $cacheOk = $cache.PackCount -gt 0
  # Ready if Python OK and (packs present OR already-generated connection files)
  $connectionOk = $manifestOk -and $onlineOk
  $ready = ($null -ne $py) -and ($cacheOk -or $connectionOk)

  $cacheDetail = if (-not $cache.DirExists) {
    "cache_files folder missing"
  } elseif ($cache.PackCount -eq 0) {
    "no .dab/.dhr/.dsb packs yet"
  } else {
    "$($cache.PackCount) packs (.dab $($cache.Dab), .dhr $($cache.Dhr), .dsb $($cache.Dsb))"
  }

  return [pscustomobject]@{
    PythonOk     = ($null -ne $py)
    PythonPath   = $py
    PythonDetail = if ($py) { "Python 3 ready" } else { "not installed / not on PATH" }
    CacheOk      = $cacheOk
    CacheCount   = $cache.PackCount
    CacheDetail  = $cacheDetail
    ManifestOk   = $manifestOk
    ManifestDetail = if ($manifestOk) { "fixed_manifest.json present" } else { "not created yet - run First-time setup" }
    OnlineOk     = $onlineOk
    OnlineDetail = if ($onlineOk) { "onlineoptions present" } else { "not created yet - run First-time setup" }
    IpOk         = [bool]$lanIp
    IpValue      = $lanIp
    IpDetail     = if ($lanIp) { $lanIp } else { "could not auto-detect - type it in setup" }
    ConnectionOk = $connectionOk
    ReadyToPlay  = $ready
    SummaryLine  = if ($ready) {
      if ($cacheOk) { "Setup looks ready ($($cache.PackCount) cache packs)." }
      else { "Setup looks ready (using existing connection files)." }
    } else {
      "Setup incomplete - choose [2] First-time setup or [3] Check setup."
    }
  }
}

function Show-SetupChecklist {
  param([switch]$PauseAtEnd)
  $status = Get-SetupStatus
  Clear-Host
  Write-Banner
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Setup checklist"
  Write-UiLine -Mode Blank
  Write-StatusLine -Ok $status.PythonOk -Label "Python" -Detail $status.PythonDetail
  Write-StatusLine -Ok $status.CacheOk -Label "Cache packs" -Detail $status.CacheDetail
  Write-UiLine -Mode Yellow -Text "     Use Android packs for Android / BlueStacks."
  Write-UiLine -Mode Yellow -Text "     Use iOS packs for iPhone / iPad (or keep them on the device)."
  Write-StatusLine -Ok $status.ManifestOk -Label "Manifest" -Detail $status.ManifestDetail
  Write-StatusLine -Ok $status.OnlineOk -Label "Online options" -Detail $status.OnlineDetail
  Write-StatusLine -Ok $status.IpOk -Label "PC address" -Detail $status.IpDetail
  Write-UiLine -Mode Blank
  if ($status.ReadyToPlay) {
    Write-UiLine -Mode Green -Text "[OK] You can try [1] Start playing."
  } else {
    Write-UiLine -Mode Yellow -Text "[!!] Not ready yet. Fix the yellow items above, then run First-time setup."
  }
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Redirect tip: AdAway (same Wi-Fi) or Technitium + Tailscale (phone)."
  Write-UiLine -Mode Yellow -Text "See README for the hostname list and phone steps."
  if ($PauseAtEnd) {
    Write-UiLine -Mode Blank
    if (-not $status.PythonOk) {
      Offer-PythonDownload
    }
    Read-Host "Press Enter to continue"
  }
  return $status
}

function Get-PatchFailureHint([int]$ExitCode, [string]$OutputText) {
  $text = [string]$OutputText
  if ($ExitCode -eq 2 -or $text -match 'Invalid IPv4') {
    return "That IP address does not look valid. Use something like 192.168.1.10 or a Tailscale 100.x.x.x address."
  }
  if ($text -match 'No package files|Cache directory not found|Android-shaped|Android or iOS') {
    return "No cache packs found. Put your .dab / .dhr / .dsb files in the cache_files folder (Android or iOS matching your client)."
  }
  if ($text -match 'missing from cache|Unlisted cache|validation failed') {
    return "Cache files do not match the manifest. Re-run setup after fixing cache_files, or use --regenerate from the README."
  }
  if ($text -match 'Missing .*fixed_manifest|cannot use --ip-only') {
    return "Connection files are missing. Put cache packs in cache_files and run First-time setup again."
  }
  if ($ExitCode -eq 1) {
    return "Setup failed. Check cache_files has your packs and the IP is correct, then try again."
  }
  return "Setup failed (error $ExitCode). Check the messages above."
}

function Invoke-ManifestPatch([string]$TargetIp, [string[]]$ExtraArgs) {
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Creating local connection files for $TargetIp ..."
  Write-UiLine -Mode Blank
  $out = & $script:PythonExe $PatchScript $TargetIp @ExtraArgs 2>&1 | ForEach-Object { "$_" }
  $code = $LASTEXITCODE
  foreach ($line in $out) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    Write-UiLine -Mode Yellow -Text ([string]$line)
  }
  return @{
    ExitCode = $code
    Output   = ($out -join "`n")
  }
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
  if (-not (Test-IPv4Address $LanIp)) {
    Clear-Host
    Write-Banner
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Detected address looks invalid: $LanIp"
    Write-UiLine -Mode Yellow -Text "Use [2] First-time setup and type a correct IPv4."
    return $false
  }
  $cache = Get-CachePackInfo
  $patchExtra = @()
  if ($cache.PackCount -le 0) {
    $manifest = Join-Path $Root "fixed_manifest.json"
    $online = Join-Path $Root "onlineoptions"
    if ((Test-Path -LiteralPath $manifest) -and (Test-Path -LiteralPath $online)) {
      Write-UiLine -Mode Blank
      Write-UiLine -Mode Yellow -Text "No cache packs in folder. Updating IP on your existing connection files."
      $patchExtra = @("--ip-only")
    } else {
      Clear-Host
      Write-Banner
      Write-UiLine -Mode Blank
      Write-UiLine -Mode Yellow -Text "No game cache packs were found."
      Write-UiLine -Mode Yellow -Text "Put Android or iOS .dab / .dhr / .dsb files in cache_files"
      Write-UiLine -Mode Yellow -Text "(matching your client), then use [2] First-time setup."
      return $false
    }
  } else {
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Green -Text ("Found $($cache.PackCount) cache packs in cache_files.")
  }
  $result = Invoke-ManifestPatch -TargetIp $LanIp -ExtraArgs $patchExtra
  if ($result.ExitCode -ne 0) {
    Clear-Host
    Write-Banner
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "Could not create connection files."
    Write-UiLine -Mode Yellow -Text (Get-PatchFailureHint $result.ExitCode $result.Output)
    Write-UiLine -Mode Yellow -Text "Then try [2] First-time setup."
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
  $summary = ""
  if ($Menu -eq "Main") {
    $summary = (Get-SetupStatus).SummaryLine
  }
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = (Get-Command powershell.exe).Source
  $psi.WorkingDirectory = $Root
  $psi.UseShellExecute = $false
  $fileArg = $UiMenu.Replace('"', '\"')
  $descArg = $desc.Replace('"', '\"')
  $summaryArg = $summary.Replace('"', '\"')
  $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$fileArg`" -Menu $Menu -BucksDescription `"$descArg`" -StatusSummary `"$summaryArg`""
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

function Invoke-GuidedSetup {
  $status = Show-SetupChecklist -PauseAtEnd
  $status = Get-SetupStatus
  if (-not $status.PythonOk) {
    Write-UiLine -Mode Yellow -Text "Python is still missing. Install it, reopen this launcher, then try setup again."
    Read-Host "Press Enter to continue"
    return
  }
  $script:PythonExe = $status.PythonPath

  Clear-Host
  Write-Banner
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "First-time setup - how will you play?"
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "[1] Emulator on this PC (BlueStacks / similar)"
  Write-UiLine -Mode Yellow -Text "    Uses this PC's Wi-Fi/Ethernet address."
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "[2] Phone / tablet on the same Wi-Fi"
  Write-UiLine -Mode Yellow -Text "    Uses this PC's LAN address + AdAway-style redirect."
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "[3] Phone / tablet with Tailscale"
  Write-UiLine -Mode Yellow -Text "    Uses your Tailscale 100.x.x.x address + Technitium DNS."
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "[4] Cancel - back to menu"
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Press 1, 2, 3, or 4:"

  $mode = $null
  while ($null -eq $mode) {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.Character) {
      "1" { $mode = "emulator" }
      "2" { $mode = "wifi" }
      "3" { $mode = "tailscale" }
      "4" { return }
    }
  }

  $lanIp = Get-LanIp
  $suggested = $lanIp
  $hint = ""
  switch ($mode) {
    "emulator" {
      $hint = "Emulator on this PC: usually your detected LAN IP is fine."
    }
    "wifi" {
      $hint = "Same Wi-Fi: use this PC's LAN IP, then point AdAway hostnames at it."
    }
    "tailscale" {
      $suggested = $null
      $hint = "Tailscale: type the PC Tailscale IPv4 (starts with 100.), not only home Wi-Fi."
    }
  }

  Clear-Host
  Write-Banner
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "This step tells the game how to reach THIS PC."
  Write-UiLine -Mode Yellow -Text $hint
  Write-UiLine -Mode Blank
  $cache = Get-CachePackInfo
  if ($cache.PackCount -gt 0) {
    Write-UiLine -Mode Green -Text ("Cache packs found: $($cache.PackCount) (.dab $($cache.Dab), .dhr $($cache.Dhr), .dsb $($cache.Dsb))")
    Write-UiLine -Mode Yellow -Text "Remember: Android client needs Android packs; iOS needs iOS packs."
  } else {
    Write-UiLine -Mode Yellow -Text "No cache packs in cache_files yet."
    Write-UiLine -Mode Yellow -Text "If the client already has caches on-device, you may still patch IP later,"
    Write-UiLine -Mode Yellow -Text "but first setup normally needs packs in cache_files."
  }
  Write-UiLine -Mode Blank
  if ($suggested) {
    Write-UiLine -Mode Yellow -Text "Suggested address: $suggested"
    Write-UiLine -Mode Yellow -Text "Press Enter to use that, or type a different IPv4."
  } else {
    Write-UiLine -Mode Yellow -Text "Type the IPv4 address the game should use."
  }
  Write-UiLine -Mode Blank
  $manifestIp = Read-Host "PC IPv4 address"
  if ([string]::IsNullOrWhiteSpace($manifestIp) -and $suggested) { $manifestIp = $suggested }
  $manifestIp = [string]$manifestIp.Trim()
  if ([string]::IsNullOrWhiteSpace($manifestIp)) {
    Write-UiLine -Mode Yellow -Text "No address entered. Returning to the menu."
    Read-Host "Press Enter to continue"
    return
  }
  if (-not (Test-IPv4Address $manifestIp)) {
    Write-UiLine -Mode Blank
    Write-UiLine -Mode Yellow -Text "That does not look like a valid IPv4 address: $manifestIp"
    Write-UiLine -Mode Yellow -Text "Example LAN: 192.168.1.10   Example Tailscale: 100.x.x.x"
    Read-Host "Press Enter to continue"
    return
  }

  $extra = @()
  if ($cache.PackCount -le 0) {
    $manifest = Join-Path $Root "fixed_manifest.json"
    $online = Join-Path $Root "onlineoptions"
    if ((Test-Path -LiteralPath $manifest) -and (Test-Path -LiteralPath $online)) {
      $extra = @("--ip-only")
      Write-UiLine -Mode Yellow -Text "Updating IP only (no new cache packs in folder)."
    }
  }

  $result = Invoke-ManifestPatch -TargetIp $manifestIp -ExtraArgs $extra
  Write-UiLine -Mode Blank
  if ($result.ExitCode -eq 0) {
    Write-UiLine -Mode Green -Text "Setup finished."
    Write-UiLine -Mode Yellow -Text "Next: redirect game hostnames to this PC, then choose [1] Start playing."
    switch ($mode) {
      "emulator" {
        Write-UiLine -Mode Yellow -Text "Emulator tip: AdAway (or hosts) on the emulator -> this PC IP."
        Write-UiLine -Mode Yellow -Text "When starting, answer Y for BlueStacks clock sync if you use BlueStacks."
      }
      "wifi" {
        Write-UiLine -Mode Yellow -Text "Phone tip: AdAway redirect hostnames to $manifestIp (see README)."
      }
      "tailscale" {
        Write-UiLine -Mode Yellow -Text "Tailscale tip: Technitium A records + Override DNS -> $manifestIp"
        Write-UiLine -Mode Yellow -Text "Keep Tailscale connected on the phone while playing."
      }
    }
  } else {
    Write-UiLine -Mode Yellow -Text (Get-PatchFailureHint $result.ExitCode $result.Output)
  }
  Write-UiLine -Mode Blank
  Read-Host "Press Enter to continue"
}

function Start-OfflineServer {
  Clear-Host
  Write-Banner
  $pre = Get-SetupStatus
  Write-UiLine -Mode Blank
  Write-UiLine -Mode Yellow -Text "Quick check before start:"
  Write-StatusLine -Ok $pre.PythonOk -Label "Python" -Detail $pre.PythonDetail
  Write-StatusLine -Ok $pre.CacheOk -Label "Cache packs" -Detail $pre.CacheDetail
  Write-StatusLine -Ok $pre.ConnectionOk -Label "Connection files" -Detail $(if ($pre.ConnectionOk) { "manifest + onlineoptions ready" } else { "need First-time setup" })
  Write-UiLine -Mode Blank

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
    5 { exit 0 }
    4 { Invoke-BucksOptions }
    3 { Show-SetupChecklist -PauseAtEnd | Out-Null }
    2 { Invoke-GuidedSetup }
    1 { Start-OfflineServer }
  }
}
