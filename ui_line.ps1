# Single centered line helper (same formula as launcher_ui.ps1).
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("Yellow", "Red", "Blank")]
  [string]$Mode,
  [string]$Text = ""
)

function Get-ConsoleWidth {
  try {
    $w = [int]$Host.UI.RawUI.WindowSize.Width
    if ($w -ge 40) { return $w }
  } catch { }
  $code = @"
using System;
using System.Runtime.InteropServices;
public static class ConSzLine {
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
  public static int GetWidth() {
    IntPtr h = CreateFileW("CONOUT$", 0x80000000 | 0x40000000, 2, IntPtr.Zero, 3, 0, IntPtr.Zero);
    if (h == IntPtr.Zero || h == new IntPtr(-1)) return 80;
    CSBI i;
    if (!GetConsoleScreenBufferInfo(h, out i)) return 80;
    int w = i.Win.Right - i.Win.Left + 1;
    return (w < 40) ? 80 : w;
  }
}
"@
  try { Add-Type -TypeDefinition $code -ErrorAction Stop | Out-Null } catch { }
  try { return [ConSzLine]::GetWidth() } catch { return 80 }
}

if ($Mode -eq "Blank") {
  Write-Host ""
  exit 0
}

if ([string]::IsNullOrEmpty($Text)) { $Text = "" }
$width = Get-ConsoleWidth
$pad = [Math]::Max(0, [Math]::Floor(($width / 2) - ($Text.Length / 2)))
$color = if ($Mode -eq "Red") { [ConsoleColor]::Red } else { [ConsoleColor]::Yellow }
Write-Host ((" " * $pad) + $Text) -ForegroundColor $color
