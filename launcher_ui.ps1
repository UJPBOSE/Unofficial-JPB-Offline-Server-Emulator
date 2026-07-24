# Draws centered launcher menus and recenters when the window is resized/maximized.
# Width comes from CONOUT$ (READ+WRITE) and RawUI; we use the larger reliable value
# so maximized Windows Terminal windows are not stuck on the pre-maximize column count.

param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("Main", "Bucks")]
  [string]$Menu,
  [string]$BucksDescription = "",
  [string]$StatusSummary = ""
)

function Get-ConsoleWidthHeight {
  $widths = New-Object System.Collections.Generic.List[int]
  $heights = New-Object System.Collections.Generic.List[int]

  try {
    $ui = $Host.UI.RawUI
    $widths.Add([int]$ui.WindowSize.Width) | Out-Null
    $heights.Add([int]$ui.WindowSize.Height) | Out-Null
    $widths.Add([int]$ui.BufferSize.Width) | Out-Null
  } catch { }

  try {
    if (-not [Console]::IsOutputRedirected) {
      $widths.Add([int][Console]::WindowWidth) | Out-Null
      $heights.Add([int][Console]::WindowHeight) | Out-Null
    }
  } catch { }

  $code = @"
using System;
using System.Runtime.InteropServices;
public static class ConSz {
  [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
  public static extern IntPtr CreateFileW(string f, uint a, uint s, IntPtr p, uint d, uint t, IntPtr h);
  [StructLayout(LayoutKind.Sequential)]
  public struct COORD { public short X; public short Y; }
  [StructLayout(LayoutKind.Sequential)]
  public struct SMALL_RECT { public short Left; public short Top; public short Right; public short Bottom; }
  [StructLayout(LayoutKind.Sequential)]
  public struct CSBI {
    public COORD Size; public COORD Cursor; public short Attrs; public SMALL_RECT Win; public COORD Max;
  }
  [DllImport("kernel32.dll", SetLastError = true)]
  public static extern bool GetConsoleScreenBufferInfo(IntPtr h, out CSBI info);
  public static int[] Get() {
    // GENERIC_READ | GENERIC_WRITE — required for GetConsoleScreenBufferInfo
    IntPtr h = CreateFileW("CONOUT$", 0x80000000 | 0x40000000, 2, IntPtr.Zero, 3, 0, IntPtr.Zero);
    if (h == IntPtr.Zero || h == new IntPtr(-1)) return new int[] { 0, 0 };
    CSBI i;
    if (!GetConsoleScreenBufferInfo(h, out i)) return new int[] { 0, 0 };
    int w = i.Win.Right - i.Win.Left + 1;
    int r = i.Win.Bottom - i.Win.Top + 1;
    return new int[] { w, r };
  }
}
"@
  try { Add-Type -TypeDefinition $code -ErrorAction Stop | Out-Null } catch { }
  try {
    $pair = [ConSz]::Get()
    if ([int]$pair[0] -ge 40) { $widths.Add([int]$pair[0]) | Out-Null }
    if ([int]$pair[1] -ge 15) { $heights.Add([int]$pair[1]) | Out-Null }
  } catch { }

  $w = 80
  $h = 25
  $validW = @($widths | Where-Object { $_ -ge 40 -and $_ -le 500 })
  $validH = @($heights | Where-Object { $_ -ge 15 -and $_ -le 200 })
  if ($validW.Count -gt 0) { $w = ($validW | Measure-Object -Maximum).Maximum }
  if ($validH.Count -gt 0) { $h = ($validH | Measure-Object -Maximum).Maximum }
  return @{ Width = $w; Height = $h }
}

function Write-HostCenter {
  param(
    [string]$Message,
    [ConsoleColor]$Color = [ConsoleColor]::Yellow
  )
  if ($null -eq $Message) { $Message = "" }
  $width = $script:ConsoleWidth
  $pad = [Math]::Max(0, [Math]::Floor(($width / 2) - ($Message.Length / 2)))
  Write-Host ((" " * $pad) + $Message) -ForegroundColor $Color
}

function Write-Blank { Write-Host "" }

function Write-Banner {
  Write-Blank
  Write-HostCenter "===============================================" Red
  Write-HostCenter "UNOFFICIAL" Yellow
  Write-HostCenter "JURASSIC PARK BUILDER" Yellow
  Write-HostCenter "Offline Server Emulator" Yellow
  Write-HostCenter "===============================================" Red
}

function Draw-MainMenu {
  $size = Get-ConsoleWidthHeight
  $script:ConsoleWidth = [int]$size.Width
  $script:ConsoleHeight = [int]$size.Height
  $blockLines = 32
  Clear-Host
  $top = [Math]::Max(0, [Math]::Floor(($script:ConsoleHeight - $blockLines) / 2))
  for ($i = 0; $i -lt $top; $i++) { Write-Blank }
  Write-Banner
  Write-Blank
  Write-HostCenter "This tool runs a local offline server on your PC."
  Write-HostCenter "You need your own game client and cache files."
  Write-Blank
  Write-HostCenter "-----------------------------------------------" Red
  Write-HostCenter ("Bucks rewards: " + $BucksDescription)
  if (-not [string]::IsNullOrWhiteSpace($StatusSummary)) {
    $summaryColor = if ($StatusSummary -like "Setup looks ready*") { [ConsoleColor]::Green } else { [ConsoleColor]::Yellow }
    Write-HostCenter $StatusSummary $summaryColor
  }
  Write-HostCenter "-----------------------------------------------" Red
  Write-Blank
  Write-HostCenter "[1] Start playing"
  Write-HostCenter "Start the offline server (recommended after setup)."
  Write-Blank
  Write-HostCenter "[2] First-time setup"
  Write-HostCenter "Guided setup: emulator, same Wi-Fi, or Tailscale."
  Write-HostCenter "Do this once, or again if your IP changes."
  Write-Blank
  Write-HostCenter "[3] Check setup status"
  Write-HostCenter "Python, cache packs, manifest, and PC address checklist."
  Write-Blank
  Write-HostCenter "[4] Change bucks rewards"
  Write-HostCenter "Choose how many bucks the server gifts you."
  Write-Blank
  Write-HostCenter "[5] Quit"
  Write-Blank
  Write-HostCenter "Press 1, 2, 3, 4, or 5:"
}

function Draw-BucksMenu {
  $size = Get-ConsoleWidthHeight
  $script:ConsoleWidth = [int]$size.Width
  $script:ConsoleHeight = [int]$size.Height
  $blockLines = 22
  Clear-Host
  $top = [Math]::Max(0, [Math]::Floor(($script:ConsoleHeight - $blockLines) / 2))
  for ($i = 0; $i -lt $top; $i++) { Write-Blank }
  Write-Banner
  Write-Blank
  Write-HostCenter "Choose how the server gifts bucks (hard cash)."
  Write-Blank
  Write-HostCenter ("Currently: " + $BucksDescription)
  Write-Blank
  Write-HostCenter "[1] Normal play"
  Write-HostCenter "5 bucks every 24 hours, and 25 every 7 days"
  Write-Blank
  Write-HostCenter "[2] Sandbox"
  Write-HostCenter "One huge gift (99999999) once per save"
  Write-Blank
  Write-HostCenter "[3] Custom"
  Write-HostCenter "Pick your own amount and how often"
  Write-Blank
  Write-HostCenter "[4] Back to main menu"
  Write-Blank
  Write-HostCenter "Press 1, 2, 3, or 4:"
}

function Wait-ForMenuChoice([scriptblock]$Redraw, [int[]]$ValidChoices) {
  & $Redraw
  while ($true) {
    $size = Get-ConsoleWidthHeight
    if ([int]$size.Width -ne $script:ConsoleWidth -or [int]$size.Height -ne $script:ConsoleHeight) {
      & $Redraw
    }
    if ($Host.UI.RawUI.KeyAvailable) {
      $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
      $ch = $key.Character
      if ($ch -match '^\d$' -and $ValidChoices -contains [int][string]$ch) {
        exit ([int][string]$ch)
      }
    }
    Start-Sleep -Milliseconds 120
  }
}

if ($Menu -eq "Main") {
  Wait-ForMenuChoice { Draw-MainMenu } @(1, 2, 3, 4, 5)
}

if ($Menu -eq "Bucks") {
  Wait-ForMenuChoice { Draw-BucksMenu } @(1, 2, 3, 4)
}
