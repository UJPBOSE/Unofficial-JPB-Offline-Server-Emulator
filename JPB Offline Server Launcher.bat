@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Unofficial Jurassic Park Builder - Offline Server
cd /d "%~dp0"
color 07

set "SERVER_SCRIPT=JPB_Offline_Server_Emulator.py"
set "SETTINGS_FILE=%~dp0launcher_settings.ini"
set "PYTHON_EXE="
call :load_settings
call :ensure_ui_files

:main_menu
call :describe_bucks_mode
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher_ui.ps1" -Menu Main -BucksDescription "!BUCKS_DESCRIPTION!"
set "MENU_CHOICE=!ERRORLEVEL!"
if "!MENU_CHOICE!"=="4" goto exit_launcher
if "!MENU_CHOICE!"=="3" goto bucks_options
if "!MENU_CHOICE!"=="2" goto patch_manifest
if "!MENU_CHOICE!"=="1" goto play
goto main_menu

:banner
call :blank
set "UITEXT==============================================="
call :red
set "UITEXT=UNOFFICIAL"
call :yellow
set "UITEXT=JURASSIC PARK BUILDER"
call :yellow
set "UITEXT=Offline Server Emulator"
call :yellow
set "UITEXT==============================================="
call :red
exit /b 0

:blank
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Blank
exit /b 0

:yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Yellow -Text "!UITEXT!"
exit /b 0

:red
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Red -Text "!UITEXT!"
exit /b 0

:describe_bucks_mode
if /I "!BUCKS_MODE!"=="legit" (
  set "BUCKS_DESCRIPTION=Normal - 5 each day, plus 25 every 7 days"
  exit /b 0
)
if /I "!BUCKS_MODE!"=="sandbox" (
  set "BUCKS_DESCRIPTION=Sandbox - a huge one-time gift per save"
  exit /b 0
)
if /I "!CUSTOM_FREQUENCY!"=="daily" (
  set "BUCKS_DESCRIPTION=Custom - !CUSTOM_AMOUNT! every 24 hours"
) else (
  set "BUCKS_DESCRIPTION=Custom - !CUSTOM_AMOUNT! on each game login"
)
exit /b 0

:load_settings
set "BUCKS_MODE=legit"
set "CUSTOM_AMOUNT=5"
set "CUSTOM_FREQUENCY=daily"
set "LOADED_MODE="
set "LOADED_AMOUNT="
set "LOADED_FREQUENCY="
if not exist "!SETTINGS_FILE!" (
  call :save_settings
  exit /b 0
)
for /f "usebackq tokens=1,* delims==" %%A in ("!SETTINGS_FILE!") do (
  if /I "%%A"=="BUCKS_MODE" set "LOADED_MODE=%%B"
  if /I "%%A"=="CUSTOM_AMOUNT" set "LOADED_AMOUNT=%%B"
  if /I "%%A"=="CUSTOM_FREQUENCY" set "LOADED_FREQUENCY=%%B"
)
if /I "!LOADED_MODE!"=="legit" set "BUCKS_MODE=legit"
if /I "!LOADED_MODE!"=="sandbox" set "BUCKS_MODE=sandbox"
if /I "!LOADED_MODE!"=="custom" set "BUCKS_MODE=custom"
if /I "!LOADED_FREQUENCY!"=="daily" set "CUSTOM_FREQUENCY=daily"
if /I "!LOADED_FREQUENCY!"=="per_login" set "CUSTOM_FREQUENCY=per_login"
set "LOADED_AMOUNT_INVALID="
for /f "delims=0123456789" %%D in ("!LOADED_AMOUNT!") do set "LOADED_AMOUNT_INVALID=%%D"
if defined LOADED_AMOUNT if not defined LOADED_AMOUNT_INVALID if "!LOADED_AMOUNT:~10,1!"=="" set "CUSTOM_AMOUNT=!LOADED_AMOUNT!"
exit /b 0

:save_settings
>"!SETTINGS_FILE!" (
  echo BUCKS_MODE=!BUCKS_MODE!
  echo CUSTOM_AMOUNT=!CUSTOM_AMOUNT!
  echo CUSTOM_FREQUENCY=!CUSTOM_FREQUENCY!
)
exit /b 0


:ensure_ui_files
if exist "%~dp0launcher_ui.ps1" if exist "%~dp0ui_line.ps1" exit /b 0
set "JPB_LAUNCHER_BAT=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -EncodedCommand CgAkAEUAcgByAG8AcgBBAGMAdABpAG8AbgBQAHIAZQBmAGUAcgBlAG4AYwBlACAAPQAgACcAUwB0AG8AcAAnAAoAJABiAGEAdABQAGEAdABoACAAPQAgACQAZQBuAHYAOgBKAFAAQgBfAEwAQQBVAE4AQwBIAEUAUgBfAEIAQQBUAAoAaQBmACAAKAAtAG4AbwB0ACAAJABiAGEAdABQAGEAdABoACkAIAB7ACAAdABoAHIAbwB3ACAAJwBKAFAAQgBfAEwAQQBVAE4AQwBIAEUAUgBfAEIAQQBUACAAbQBpAHMAcwBpAG4AZwAnACAAfQAKACQAZABpAHIAIAA9ACAAUwBwAGwAaQB0AC0AUABhAHQAaAAgAC0ATABpAHQAZQByAGEAbABQAGEAdABoACAAJABiAGEAdABQAGEAdABoAAoAJAByAGEAdwAgAD0AIABHAGUAdAAtAEMAbwBuAHQAZQBuAHQAIAAtAEwAaQB0AGUAcgBhAGwAUABhAHQAaAAgACQAYgBhAHQAUABhAHQAaAAgAC0AUgBhAHcACgAkAG0AIAA9ACAAWwByAGUAZwBlAHgAXQA6ADoATQBhAHQAYwBoACgAJAByAGEAdwAsACAAJwAoAD8AcwApADoAOgAgAEIARQBHAEkATgBfAEwAQQBVAE4AQwBIAEUAUgBfAFUASQBfAFAAQQBZAEwATwBBAEQAXAByAD8AXABuACgALgAqAD8AKQA6ADoAIABFAE4ARABfAEwAQQBVAE4AQwBIAEUAUgBfAFUASQBfAFAAQQBZAEwATwBBAEQAJwApAAoAaQBmACAAKAAtAG4AbwB0ACAAJABtAC4AUwB1AGMAYwBlAHMAcwApACAAewAgAGUAeABpAHQAIAAyACAAfQAKACQAYgBsAG8AYwBrACAAPQAgACQAbQAuAEcAcgBvAHUAcABzAFsAMQBdAC4AVgBhAGwAdQBlAAoAJABjAHUAcgByAGUAbgB0ACAAPQAgACQAbgB1AGwAbAAKACQAYgB1AGYAIAA9ACAATgBlAHcALQBPAGIAagBlAGMAdAAgAFMAeQBzAHQAZQBtAC4AVABlAHgAdAAuAFMAdAByAGkAbgBnAEIAdQBpAGwAZABlAHIACgBmAHUAbgBjAHQAaQBvAG4AIABGAGwAdQBzAGgALQBGAGkAbABlACgAWwBzAHQAcgBpAG4AZwBdACQAbgBhAG0AZQAsACAAWwBzAHQAcgBpAG4AZwBdACQAYgA2ADQAKQAgAHsACgAgACAAaQBmACAAKABbAHMAdAByAGkAbgBnAF0AOgA6AEkAcwBOAHUAbABsAE8AcgBXAGgAaQB0AGUAUwBwAGEAYwBlACgAJABuAGEAbQBlACkAIAAtAG8AcgAgAFsAcwB0AHIAaQBuAGcAXQA6ADoASQBzAE4AdQBsAGwATwByAFcAaABpAHQAZQBTAHAAYQBjAGUAKAAkAGIANgA0ACkAKQAgAHsAIAByAGUAdAB1AHIAbgAgAH0ACgAgACAAJABwAGEAdABoACAAPQAgAEoAbwBpAG4ALQBQAGEAdABoACAAJABkAGkAcgAgACQAbgBhAG0AZQAKACAAIABpAGYAIAAoAC0AbgBvAHQAIAAoAFQAZQBzAHQALQBQAGEAdABoACAALQBMAGkAdABlAHIAYQBsAFAAYQB0AGgAIAAkAHAAYQB0AGgAKQApACAAewAKACAAIAAgACAAWwBJAE8ALgBGAGkAbABlAF0AOgA6AFcAcgBpAHQAZQBBAGwAbABCAHkAdABlAHMAKAAkAHAAYQB0AGgALAAgAFsAQwBvAG4AdgBlAHIAdABdADoAOgBGAHIAbwBtAEIAYQBzAGUANgA0AFMAdAByAGkAbgBnACgAKAAkAGIANgA0ACAALQByAGUAcABsAGEAYwBlACAAJwBcAHMAJwAsACcAJwApACkAKQAKACAAIAB9AAoAfQAKAGYAbwByAGUAYQBjAGgAIAAoACQAbABpAG4AZQAgAGkAbgAgACgAJABiAGwAbwBjAGsAIAAtAHMAcABsAGkAdAAgACcAXAByAD8AXABuACcAKQApACAAewAKACAAIABpAGYAIAAoACQAbABpAG4AZQAgAC0AbQBhAHQAYwBoACAAJwBeADoAOgAgAEYASQBMAEUAIAAoAC4AKwApACQAJwApACAAewAKACAAIAAgACAAaQBmACAAKAAkAGMAdQByAHIAZQBuAHQAKQAgAHsAIABGAGwAdQBzAGgALQBGAGkAbABlACAAJABjAHUAcgByAGUAbgB0ACAAJABiAHUAZgAuAFQAbwBTAHQAcgBpAG4AZwAoACkAOwAgAFsAdgBvAGkAZABdACQAYgB1AGYALgBDAGwAZQBhAHIAKAApACAAfQAKACAAIAAgACAAJABjAHUAcgByAGUAbgB0ACAAPQAgACQATQBhAHQAYwBoAGUAcwBbADEAXQAuAFQAcgBpAG0AKAApAAoAIAAgACAAIABjAG8AbgB0AGkAbgB1AGUACgAgACAAfQAKACAAIABpAGYAIAAoACQAbABpAG4AZQAgAC0AbQBhAHQAYwBoACAAJwBeADoAOgAgACgAWwBBAC0AWgBhAC0AegAwAC0AOQArAC8APQBdACsAKQAkACcAKQAgAHsAIABbAHYAbwBpAGQAXQAkAGIAdQBmAC4AQQBwAHAAZQBuAGQAKAAkAE0AYQB0AGMAaABlAHMAWwAxAF0AKQAgAH0ACgB9AAoAaQBmACAAKAAkAGMAdQByAHIAZQBuAHQAKQAgAHsAIABGAGwAdQBzAGgALQBGAGkAbABlACAAJABjAHUAcgByAGUAbgB0ACAAJABiAHUAZgAuAFQAbwBTAHQAcgBpAG4AZwAoACkAIAB9AAoA
set "JPB_LAUNCHER_BAT="
if exist "%~dp0launcher_ui.ps1" if exist "%~dp0ui_line.ps1" exit /b 0
echo.
echo Could not restore launcher_ui.ps1 / ui_line.ps1 next to this launcher.
echo Download the full project folder from GitHub.
echo.
pause
exit 1

:bucks_options
call :describe_bucks_mode
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher_ui.ps1" -Menu Bucks -BucksDescription "!BUCKS_DESCRIPTION!"
set "OPTION_CHOICE=!ERRORLEVEL!"
if "!OPTION_CHOICE!"=="4" goto main_menu
if "!OPTION_CHOICE!"=="3" goto custom_bucks
if "!OPTION_CHOICE!"=="2" (
  set "BUCKS_MODE=sandbox"
  call :save_settings
  call :blank
  set "UITEXT=Sandbox selected. The one-time gift is saved with your game."
  call :yellow
  call :blank
  pause
  goto main_menu
)
if "!OPTION_CHOICE!"=="1" (
  set "BUCKS_MODE=legit"
  call :save_settings
  call :blank
  set "UITEXT=Normal play selected."
  call :yellow
  call :blank
  pause
  goto main_menu
)
goto bucks_options

:custom_bucks
call :resolve_python
if errorlevel 1 (
  pause
  goto bucks_options
)
call :blank
set "CUSTOM_INPUT="
set /p "CUSTOM_INPUT=How many bucks? (1-2000000000): "
set "AMOUNT_TO_VALIDATE=!CUSTOM_INPUT!"
call :validate_amount
if not "!VALID_AMOUNT!"=="1" (
  set "UITEXT=Please enter numbers only, from 1 to 2000000000."
  call :yellow
  pause
  goto custom_bucks
)
call :blank
set "UITEXT=How often should they be gifted?"
call :yellow
set "UITEXT=[1] Every time the game logs into the server"
call :yellow
set "UITEXT=[2] Once every 24 hours"
call :yellow
call :blank
set "UITEXT=Press 1 or 2:"
call :yellow
choice /C 12 /N
if errorlevel 2 (
  set "CUSTOM_FREQUENCY=daily"
) else (
  set "CUSTOM_FREQUENCY=per_login"
)
set "CUSTOM_AMOUNT=!CUSTOM_INPUT!"
set "BUCKS_MODE=custom"
call :save_settings
call :blank
set "UITEXT=Custom bucks settings saved."
call :yellow
call :blank
pause
goto main_menu

:validate_amount
set "VALID_AMOUNT=0"
if not defined PYTHON_EXE exit /b 0
"!PYTHON_EXE!" -c "import sys; value=int(sys.argv[1]); raise SystemExit(0 if value in range(1, 2000000001) else 1)" "!AMOUNT_TO_VALIDATE!" >nul 2>&1
if not errorlevel 1 set "VALID_AMOUNT=1"
exit /b 0

:patch_manifest
cls
call :vpad 16
call :banner
call :resolve_python
if errorlevel 1 (
  pause
  goto main_menu
)
call :detect_lan_ip
call :blank
set "UITEXT=This step tells the game how to reach THIS PC."
call :yellow
set "UITEXT=Put your cache files in the cache_files folder first."
call :yellow
call :blank
if defined LAN_IP (
  set "UITEXT=Detected PC address: !LAN_IP!"
  call :yellow
  set "UITEXT=Press Enter to use that, or type a different IPv4."
  call :yellow
) else (
  set "UITEXT=Could not detect your PC address automatically."
  call :yellow
  set "UITEXT=Find it with ipconfig (IPv4 Address), then type it below."
  call :yellow
)
call :blank
set "MANIFEST_IP="
set /p "MANIFEST_IP=PC IPv4 address: "
if not defined MANIFEST_IP if defined LAN_IP set "MANIFEST_IP=!LAN_IP!"
if not defined MANIFEST_IP (
  set "UITEXT=No address entered. Returning to the menu."
  call :yellow
  pause
  goto main_menu
)
call :blank
set "UITEXT=Creating local connection files..."
call :yellow
call :blank
"!PYTHON_EXE!" "%~dp0patch_manifest_ip.py" "!MANIFEST_IP!"
set "PATCH_EXIT=!ERRORLEVEL!"
call :blank
if "!PATCH_EXIT!"=="0" (
  set "UITEXT=Setup finished. You can now choose [1] Start playing."
  call :yellow
) else (
  set "UITEXT=Setup failed (error !PATCH_EXIT!)."
  call :yellow
  set "UITEXT=Check that cache_files has your packs, then try again."
  call :yellow
)
call :blank
pause
goto main_menu

:play
cls
call :banner
call :resolve_python
if errorlevel 1 (
  pause
  goto main_menu
)
if /I "!BUCKS_MODE!"=="custom" (
  set "AMOUNT_TO_VALIDATE=!CUSTOM_AMOUNT!"
  call :validate_amount
  if not "!VALID_AMOUNT!"=="1" (
    set "UITEXT=Saved custom amount was invalid. Switching back to Normal play."
    call :yellow
    set "BUCKS_MODE=legit"
    set "CUSTOM_AMOUNT=5"
    set "CUSTOM_FREQUENCY=daily"
    call :save_settings
  )
)

call :blank
set "UITEXT=Preparing to start..."
call :yellow
set "UITEXT=Stopping any old server still running..."
call :yellow
powershell -NoProfile -Command "for ($pass = 0; $pass -lt 3; $pass++) { Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'python*.exe' -and $_.CommandLine -like '*JPB_Offline_Server_Emulator.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; Start-Sleep -Milliseconds 250 }"
set "UITEXT=Freeing ports 80, 9933, and 9943 if needed..."
call :yellow
for %%P in (80 9933 9943) do (
  for /f "tokens=5" %%A in ('netstat -ano ^| findstr /R /C:":%%P .*LISTENING"') do taskkill /F /PID %%A >nul 2>&1
)

call :detect_lan_ip
if defined LAN_IP (
  call :blank
  set "UITEXT=Your PC address: !LAN_IP!"
  call :yellow
  set "UITEXT=Game should connect to this PC on your home network."
  call :yellow
)

call :ensure_local_generated_files
if errorlevel 1 (
  pause
  goto main_menu
)

set "MAIL_POLICY=legit"
set "MAIL_AMOUNT=5"
if /I "!BUCKS_MODE!"=="sandbox" (
  set "MAIL_POLICY=sandbox_once"
  set "MAIL_AMOUNT=99999999"
)
if /I "!BUCKS_MODE!"=="custom" (
  set "MAIL_POLICY=!CUSTOM_FREQUENCY!"
  set "MAIL_AMOUNT=!CUSTOM_AMOUNT!"
)
call :describe_bucks_mode
set "UITEXT=Bucks rewards: !BUCKS_DESCRIPTION!"
call :yellow

set "ADB_EXE="
set "ADB_SERIAL="
set "ADB_ARGS="
call :blank
set "UITEXT=If you use BlueStacks, answer Y so game timers stay in sync."
call :yellow
set "UITEXT=Answer N if you are not using BlueStacks."
call :yellow
call :blank
set "UITEXT=Use BlueStacks clock sync? [Y/N]:"
call :yellow
choice /C YN /N
if errorlevel 2 (
  set "UITEXT=Starting without BlueStacks sync."
  call :yellow
  goto start_server
)
if exist "C:\Program Files\BlueStacks_nxt\HD-Adb.exe" set "ADB_EXE=C:\Program Files\BlueStacks_nxt\HD-Adb.exe"
if not defined ADB_EXE if exist "C:\Program Files\BlueStacks\HD-Adb.exe" set "ADB_EXE=C:\Program Files\BlueStacks\HD-Adb.exe"
if not defined ADB_EXE if exist "C:\Program Files (x86)\BlueStacks\HD-Adb.exe" set "ADB_EXE=C:\Program Files (x86)\BlueStacks\HD-Adb.exe"
if not defined ADB_EXE (
  set "UITEXT=BlueStacks was not found. Starting without clock sync."
  call :yellow
  goto start_server
)
"!ADB_EXE!" connect 127.0.0.1:5555 >nul 2>&1
for /f "usebackq delims=" %%S in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$adb=$env:ADB_EXE; $preferred=@('emulator-5554','127.0.0.1:5555'); $lines=& $adb devices 2>$null; $devices=@(); foreach($line in $lines){ if($line -match '^(\S+)\s+device$'){ $devices += $matches[1] } }; foreach($p in $preferred){ if($devices -contains $p){ Write-Output $p; exit 0 } }; if($devices.Count -gt 0){ Write-Output $devices[0] }"`) do set "ADB_SERIAL=%%S"
if not defined ADB_SERIAL (
  set "UITEXT=No BlueStacks device found. Starting without clock sync."
  call :yellow
  goto start_server
)
set "UITEXT=BlueStacks connected. Clock sync is on."
call :yellow
set "ADB_ARGS=--adb-logcat --adb-path "!ADB_EXE!" --adb-serial "!ADB_SERIAL!" --sync-adb-clock --adb-clock-max-drift-seconds 5 --adb-clock-sync-interval-seconds 60 --adb-timezone auto"

:start_server
call :blank
set "UITEXT=Starting the offline server..."
call :yellow
set "UITEXT=Leave this window open while you play."
call :yellow
set "UITEXT=Press Ctrl+C here when you want to stop."
call :yellow
call :blank
"!PYTHON_EXE!" "!SERVER_SCRIPT!" --host 0.0.0.0 --game-services-mode generic --composite-profile savegame --mail-mode hardcash --hardcash-gift-policy "!MAIL_POLICY!" --hardcash-gift-amount "!MAIL_AMOUNT!" --friend-mode random_user_stub --post-login-push online_options !ADB_ARGS! %*
set "SERVER_EXIT=!ERRORLEVEL!"
call :blank
set "UITEXT=Server stopped (code !SERVER_EXIT!)."
call :yellow
call :blank
pause
goto main_menu

:ensure_local_generated_files
:: Build gitignored fixed_manifest.json + onlineoptions on Play when missing,
:: or refresh the manifest IP to the detected LAN address.
if not defined LAN_IP (
  set "UITEXT=Could not detect your PC's network address."
  call :yellow
  set "UITEXT=Use menu [2] First-time setup and type your IPv4 manually,"
  call :yellow
  set "UITEXT=or connect to Wi-Fi / Ethernet and try again."
  call :yellow
  exit /b 1
)
if not exist "%~dp0cache_files\" (
  set "UITEXT=Missing cache_files folder."
  call :yellow
  set "UITEXT=Put your own cache packs in cache_files, then try again."
  call :yellow
  exit /b 1
)
call :blank
set "UITEXT=Checking connection files for !LAN_IP! ..."
call :yellow
"!PYTHON_EXE!" "%~dp0patch_manifest_ip.py" "!LAN_IP!"
if errorlevel 1 (
  set "UITEXT=Could not create connection files."
  call :yellow
  set "UITEXT=Make sure cache_files has your .dab / .dhr / .dsb packs."
  call :yellow
  exit /b 1
)
exit /b 0

:resolve_python
if defined PYTHON_EXE if exist "!PYTHON_EXE!" exit /b 0
set "PYTHON_EXE="
for %%P in (
  "%~dp0.venv\Scripts\python.exe"
  "%LOCALAPPDATA%\Python\pythoncore-3.14-64\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python314\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python313\python.exe"
  "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
) do if not defined PYTHON_EXE if exist "%%~fP" set "PYTHON_EXE=%%~fP"
if not defined PYTHON_EXE (
  for /f "delims=" %%P in ('where python.exe 2^>nul') do (
    set "PYTHON_CANDIDATE=%%~fP"
    set "NON_STORE_CANDIDATE=!PYTHON_CANDIDATE:\WindowsApps\=!"
    if /I "!NON_STORE_CANDIDATE!"=="!PYTHON_CANDIDATE!" if not defined PYTHON_EXE set "PYTHON_EXE=!PYTHON_CANDIDATE!"
  )
)
if not defined PYTHON_EXE (
  where py.exe >nul 2>&1
  if not errorlevel 1 for /f "delims=" %%P in ('py -3 -c "import sys; print(sys.executable)" 2^>nul') do if exist "%%~fP" set "PYTHON_EXE=%%~fP"
)
if not defined PYTHON_EXE (
  call :blank
  set "UITEXT=Python was not found on this PC."
  call :yellow
  set "UITEXT=Install Python 3 from python.org, then try again."
  call :yellow
  exit /b 1
)
"!PYTHON_EXE!" -c "import sys; ok=sys.version_info[0] == 3 and sys.version_info[1] in range(10, 100); raise SystemExit(0 if ok else 1)" >nul 2>&1
if errorlevel 1 (
  set "UITEXT=Python 3.10 or newer is required."
  call :yellow
  set "UITEXT=Found: !PYTHON_EXE!"
  call :yellow
  set "PYTHON_EXE="
  exit /b 1
)
exit /b 0

:detect_lan_ip
set "LAN_IP="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$ip=(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1 -ExpandProperty IPv4Address | Select-Object -First 1 -ExpandProperty IPAddress); if($ip){$ip}"`) do set "LAN_IP=%%I"
exit /b 0

:exit_launcher
endlocal
exit /b 0

:: BEGIN_LAUNCHER_UI_PAYLOAD
:: FILE launcher_ui.ps1
:: IyBEcmF3cyBjZW50ZXJlZCBsYXVuY2hlciBtZW51cyBhbmQgcmVjZW50ZXJzIHdoZW4gdGhlIHdp
:: bmRvdyBpcyByZXNpemVkL21heGltaXplZC4NCiMgV2lkdGggY29tZXMgZnJvbSBDT05PVVQkIChS
:: RUFEK1dSSVRFKSBhbmQgUmF3VUk7IHdlIHVzZSB0aGUgbGFyZ2VyIHJlbGlhYmxlIHZhbHVlDQoj
:: IHNvIG1heGltaXplZCBXaW5kb3dzIFRlcm1pbmFsIHdpbmRvd3MgYXJlIG5vdCBzdHVjayBvbiB0
:: aGUgcHJlLW1heGltaXplIGNvbHVtbiBjb3VudC4NCg0KcGFyYW0oDQogIFtQYXJhbWV0ZXIoTWFu
:: ZGF0b3J5ID0gJHRydWUpXQ0KICBbVmFsaWRhdGVTZXQoIk1haW4iLCAiQnVja3MiKV0NCiAgW3N0
:: cmluZ10kTWVudSwNCiAgW3N0cmluZ10kQnVja3NEZXNjcmlwdGlvbiA9ICIiDQopDQoNCmZ1bmN0
:: aW9uIEdldC1Db25zb2xlV2lkdGhIZWlnaHQgew0KICAkd2lkdGhzID0gTmV3LU9iamVjdCBTeXN0
:: ZW0uQ29sbGVjdGlvbnMuR2VuZXJpYy5MaXN0W2ludF0NCiAgJGhlaWdodHMgPSBOZXctT2JqZWN0
:: IFN5c3RlbS5Db2xsZWN0aW9ucy5HZW5lcmljLkxpc3RbaW50XQ0KDQogIHRyeSB7DQogICAgJHVp
:: ID0gJEhvc3QuVUkuUmF3VUkNCiAgICAkd2lkdGhzLkFkZChbaW50XSR1aS5XaW5kb3dTaXplLldp
:: ZHRoKSB8IE91dC1OdWxsDQogICAgJGhlaWdodHMuQWRkKFtpbnRdJHVpLldpbmRvd1NpemUuSGVp
:: Z2h0KSB8IE91dC1OdWxsDQogICAgJHdpZHRocy5BZGQoW2ludF0kdWkuQnVmZmVyU2l6ZS5XaWR0
:: aCkgfCBPdXQtTnVsbA0KICB9IGNhdGNoIHsgfQ0KDQogIHRyeSB7DQogICAgaWYgKC1ub3QgW0Nv
:: bnNvbGVdOjpJc091dHB1dFJlZGlyZWN0ZWQpIHsNCiAgICAgICR3aWR0aHMuQWRkKFtpbnRdW0Nv
:: bnNvbGVdOjpXaW5kb3dXaWR0aCkgfCBPdXQtTnVsbA0KICAgICAgJGhlaWdodHMuQWRkKFtpbnRd
:: W0NvbnNvbGVdOjpXaW5kb3dIZWlnaHQpIHwgT3V0LU51bGwNCiAgICB9DQogIH0gY2F0Y2ggeyB9
:: DQoNCiAgJGNvZGUgPSBAIg0KdXNpbmcgU3lzdGVtOw0KdXNpbmcgU3lzdGVtLlJ1bnRpbWUuSW50
:: ZXJvcFNlcnZpY2VzOw0KcHVibGljIHN0YXRpYyBjbGFzcyBDb25TeiB7DQogIFtEbGxJbXBvcnQo
:: Imtlcm5lbDMyLmRsbCIsIFNldExhc3RFcnJvciA9IHRydWUsIENoYXJTZXQgPSBDaGFyU2V0LlVu
:: aWNvZGUpXQ0KICBwdWJsaWMgc3RhdGljIGV4dGVybiBJbnRQdHIgQ3JlYXRlRmlsZVcoc3RyaW5n
:: IGYsIHVpbnQgYSwgdWludCBzLCBJbnRQdHIgcCwgdWludCBkLCB1aW50IHQsIEludFB0ciBoKTsN
:: CiAgW1N0cnVjdExheW91dChMYXlvdXRLaW5kLlNlcXVlbnRpYWwpXQ0KICBwdWJsaWMgc3RydWN0
:: IENPT1JEIHsgcHVibGljIHNob3J0IFg7IHB1YmxpYyBzaG9ydCBZOyB9DQogIFtTdHJ1Y3RMYXlv
:: dXQoTGF5b3V0S2luZC5TZXF1ZW50aWFsKV0NCiAgcHVibGljIHN0cnVjdCBTTUFMTF9SRUNUIHsg
:: cHVibGljIHNob3J0IExlZnQ7IHB1YmxpYyBzaG9ydCBUb3A7IHB1YmxpYyBzaG9ydCBSaWdodDsg
:: cHVibGljIHNob3J0IEJvdHRvbTsgfQ0KICBbU3RydWN0TGF5b3V0KExheW91dEtpbmQuU2VxdWVu
:: dGlhbCldDQogIHB1YmxpYyBzdHJ1Y3QgQ1NCSSB7DQogICAgcHVibGljIENPT1JEIFNpemU7IHB1
:: YmxpYyBDT09SRCBDdXJzb3I7IHB1YmxpYyBzaG9ydCBBdHRyczsgcHVibGljIFNNQUxMX1JFQ1Qg
:: V2luOyBwdWJsaWMgQ09PUkQgTWF4Ow0KICB9DQogIFtEbGxJbXBvcnQoImtlcm5lbDMyLmRsbCIs
:: IFNldExhc3RFcnJvciA9IHRydWUpXQ0KICBwdWJsaWMgc3RhdGljIGV4dGVybiBib29sIEdldENv
:: bnNvbGVTY3JlZW5CdWZmZXJJbmZvKEludFB0ciBoLCBvdXQgQ1NCSSBpbmZvKTsNCiAgcHVibGlj
:: IHN0YXRpYyBpbnRbXSBHZXQoKSB7DQogICAgLy8gR0VORVJJQ19SRUFEIHwgR0VORVJJQ19XUklU
:: RSDigJQgcmVxdWlyZWQgZm9yIEdldENvbnNvbGVTY3JlZW5CdWZmZXJJbmZvDQogICAgSW50UHRy
:: IGggPSBDcmVhdGVGaWxlVygiQ09OT1VUJCIsIDB4ODAwMDAwMDAgfCAweDQwMDAwMDAwLCAyLCBJ
:: bnRQdHIuWmVybywgMywgMCwgSW50UHRyLlplcm8pOw0KICAgIGlmIChoID09IEludFB0ci5aZXJv
:: IHx8IGggPT0gbmV3IEludFB0cigtMSkpIHJldHVybiBuZXcgaW50W10geyAwLCAwIH07DQogICAg
:: Q1NCSSBpOw0KICAgIGlmICghR2V0Q29uc29sZVNjcmVlbkJ1ZmZlckluZm8oaCwgb3V0IGkpKSBy
:: ZXR1cm4gbmV3IGludFtdIHsgMCwgMCB9Ow0KICAgIGludCB3ID0gaS5XaW4uUmlnaHQgLSBpLldp
:: bi5MZWZ0ICsgMTsNCiAgICBpbnQgciA9IGkuV2luLkJvdHRvbSAtIGkuV2luLlRvcCArIDE7DQog
:: ICAgcmV0dXJuIG5ldyBpbnRbXSB7IHcsIHIgfTsNCiAgfQ0KfQ0KIkANCiAgdHJ5IHsgQWRkLVR5
:: cGUgLVR5cGVEZWZpbml0aW9uICRjb2RlIC1FcnJvckFjdGlvbiBTdG9wIHwgT3V0LU51bGwgfSBj
:: YXRjaCB7IH0NCiAgdHJ5IHsNCiAgICAkcGFpciA9IFtDb25Tel06OkdldCgpDQogICAgaWYgKFtp
:: bnRdJHBhaXJbMF0gLWdlIDQwKSB7ICR3aWR0aHMuQWRkKFtpbnRdJHBhaXJbMF0pIHwgT3V0LU51
:: bGwgfQ0KICAgIGlmIChbaW50XSRwYWlyWzFdIC1nZSAxNSkgeyAkaGVpZ2h0cy5BZGQoW2ludF0k
:: cGFpclsxXSkgfCBPdXQtTnVsbCB9DQogIH0gY2F0Y2ggeyB9DQoNCiAgJHcgPSA4MA0KICAkaCA9
:: IDI1DQogICR2YWxpZFcgPSBAKCR3aWR0aHMgfCBXaGVyZS1PYmplY3QgeyAkXyAtZ2UgNDAgLWFu
:: ZCAkXyAtbGUgNTAwIH0pDQogICR2YWxpZEggPSBAKCRoZWlnaHRzIHwgV2hlcmUtT2JqZWN0IHsg
:: JF8gLWdlIDE1IC1hbmQgJF8gLWxlIDIwMCB9KQ0KICBpZiAoJHZhbGlkVy5Db3VudCAtZ3QgMCkg
:: eyAkdyA9ICgkdmFsaWRXIHwgTWVhc3VyZS1PYmplY3QgLU1heGltdW0pLk1heGltdW0gfQ0KICBp
:: ZiAoJHZhbGlkSC5Db3VudCAtZ3QgMCkgeyAkaCA9ICgkdmFsaWRIIHwgTWVhc3VyZS1PYmplY3Qg
:: LU1heGltdW0pLk1heGltdW0gfQ0KICByZXR1cm4gQHsgV2lkdGggPSAkdzsgSGVpZ2h0ID0gJGgg
:: fQ0KfQ0KDQpmdW5jdGlvbiBXcml0ZS1Ib3N0Q2VudGVyIHsNCiAgcGFyYW0oDQogICAgW3N0cmlu
:: Z10kTWVzc2FnZSwNCiAgICBbQ29uc29sZUNvbG9yXSRDb2xvciA9IFtDb25zb2xlQ29sb3JdOjpZ
:: ZWxsb3cNCiAgKQ0KICBpZiAoJG51bGwgLWVxICRNZXNzYWdlKSB7ICRNZXNzYWdlID0gIiIgfQ0K
:: ICAkd2lkdGggPSAkc2NyaXB0OkNvbnNvbGVXaWR0aA0KICAkcGFkID0gW01hdGhdOjpNYXgoMCwg
:: W01hdGhdOjpGbG9vcigoJHdpZHRoIC8gMikgLSAoJE1lc3NhZ2UuTGVuZ3RoIC8gMikpKQ0KICBX
:: cml0ZS1Ib3N0ICgoIiAiICogJHBhZCkgKyAkTWVzc2FnZSkgLUZvcmVncm91bmRDb2xvciAkQ29s
:: b3INCn0NCg0KZnVuY3Rpb24gV3JpdGUtQmxhbmsgeyBXcml0ZS1Ib3N0ICIiIH0NCg0KZnVuY3Rp
:: b24gV3JpdGUtQmFubmVyIHsNCiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9zdENlbnRlciAiPT09
:: PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT0iIFJlZA0KICBXcml0
:: ZS1Ib3N0Q2VudGVyICJVTk9GRklDSUFMIiBZZWxsb3cNCiAgV3JpdGUtSG9zdENlbnRlciAiSlVS
:: QVNTSUMgUEFSSyBCVUlMREVSIiBZZWxsb3cNCiAgV3JpdGUtSG9zdENlbnRlciAiT2ZmbGluZSBT
:: ZXJ2ZXIgRW11bGF0b3IiIFllbGxvdw0KICBXcml0ZS1Ib3N0Q2VudGVyICI9PT09PT09PT09PT09
:: PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PSIgUmVkDQp9DQoNCmZ1bmN0aW9uIERy
:: YXctTWFpbk1lbnUgew0KICAkc2l6ZSA9IEdldC1Db25zb2xlV2lkdGhIZWlnaHQNCiAgJHNjcmlw
:: dDpDb25zb2xlV2lkdGggPSBbaW50XSRzaXplLldpZHRoDQogICRzY3JpcHQ6Q29uc29sZUhlaWdo
:: dCA9IFtpbnRdJHNpemUuSGVpZ2h0DQogICRibG9ja0xpbmVzID0gMjYNCiAgQ2xlYXItSG9zdA0K
:: ICAkdG9wID0gW01hdGhdOjpNYXgoMCwgW01hdGhdOjpGbG9vcigoJHNjcmlwdDpDb25zb2xlSGVp
:: Z2h0IC0gJGJsb2NrTGluZXMpIC8gMikpDQogIGZvciAoJGkgPSAwOyAkaSAtbHQgJHRvcDsgJGkr
:: KykgeyBXcml0ZS1CbGFuayB9DQogIFdyaXRlLUJhbm5lcg0KICBXcml0ZS1CbGFuaw0KICBXcml0
:: ZS1Ib3N0Q2VudGVyICJUaGlzIHRvb2wgcnVucyBhIGxvY2FsIG9mZmxpbmUgc2VydmVyIG9uIHlv
:: dXIgUEMuIg0KICBXcml0ZS1Ib3N0Q2VudGVyICJZb3UgbmVlZCB5b3VyIG93biBnYW1lIGNsaWVu
:: dCBhbmQgY2FjaGUgZmlsZXMuIg0KICBXcml0ZS1CbGFuaw0KICBXcml0ZS1Ib3N0Q2VudGVyICIt
:: LS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIgUmVkDQogIFdy
:: aXRlLUhvc3RDZW50ZXIgKCJCdWNrcyByZXdhcmRzOiAiICsgJEJ1Y2tzRGVzY3JpcHRpb24pDQog
:: IFdyaXRlLUhvc3RDZW50ZXIgIi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0t
:: LS0tLS0tLS0tIiBSZWQNCiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9zdENlbnRlciAiWzFdIFN0
:: YXJ0IHBsYXlpbmciDQogIFdyaXRlLUhvc3RDZW50ZXIgIlN0YXJ0IHRoZSBvZmZsaW5lIHNlcnZl
:: ciAocmVjb21tZW5kZWQgYWZ0ZXIgc2V0dXApLiINCiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9z
:: dENlbnRlciAiWzJdIEZpcnN0LXRpbWUgc2V0dXAiDQogIFdyaXRlLUhvc3RDZW50ZXIgIkxpbmsg
:: dGhlIGdhbWUgdG8gdGhpcyBQQydzIElQIGFkZHJlc3MuIg0KICBXcml0ZS1Ib3N0Q2VudGVyICJE
:: byB0aGlzIG9uY2UsIG9yIGFnYWluIGlmIHlvdXIgSVAgY2hhbmdlcy4iDQogIFdyaXRlLUJsYW5r
:: DQogIFdyaXRlLUhvc3RDZW50ZXIgIlszXSBDaGFuZ2UgYnVja3MgcmV3YXJkcyINCiAgV3JpdGUt
:: SG9zdENlbnRlciAiQ2hvb3NlIGhvdyBtYW55IGJ1Y2tzIHRoZSBzZXJ2ZXIgZ2lmdHMgeW91LiIN
:: CiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9zdENlbnRlciAiWzRdIFF1aXQiDQogIFdyaXRlLUJs
:: YW5rDQogIFdyaXRlLUhvc3RDZW50ZXIgIlByZXNzIDEsIDIsIDMsIG9yIDQ6Ig0KfQ0KDQpmdW5j
:: dGlvbiBEcmF3LUJ1Y2tzTWVudSB7DQogICRzaXplID0gR2V0LUNvbnNvbGVXaWR0aEhlaWdodA0K
:: ICAkc2NyaXB0OkNvbnNvbGVXaWR0aCA9IFtpbnRdJHNpemUuV2lkdGgNCiAgJHNjcmlwdDpDb25z
:: b2xlSGVpZ2h0ID0gW2ludF0kc2l6ZS5IZWlnaHQNCiAgJGJsb2NrTGluZXMgPSAyMg0KICBDbGVh
:: ci1Ib3N0DQogICR0b3AgPSBbTWF0aF06Ok1heCgwLCBbTWF0aF06OkZsb29yKCgkc2NyaXB0OkNv
:: bnNvbGVIZWlnaHQgLSAkYmxvY2tMaW5lcykgLyAyKSkNCiAgZm9yICgkaSA9IDA7ICRpIC1sdCAk
:: dG9wOyAkaSsrKSB7IFdyaXRlLUJsYW5rIH0NCiAgV3JpdGUtQmFubmVyDQogIFdyaXRlLUJsYW5r
:: DQogIFdyaXRlLUhvc3RDZW50ZXIgIkNob29zZSBob3cgdGhlIHNlcnZlciBnaWZ0cyBidWNrcyAo
:: aGFyZCBjYXNoKS4iDQogIFdyaXRlLUJsYW5rDQogIFdyaXRlLUhvc3RDZW50ZXIgKCJDdXJyZW50
:: bHk6ICIgKyAkQnVja3NEZXNjcmlwdGlvbikNCiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9zdENl
:: bnRlciAiWzFdIE5vcm1hbCBwbGF5Ig0KICBXcml0ZS1Ib3N0Q2VudGVyICI1IGJ1Y2tzIGV2ZXJ5
:: IDI0IGhvdXJzLCBhbmQgMjUgZXZlcnkgNyBkYXlzIg0KICBXcml0ZS1CbGFuaw0KICBXcml0ZS1I
:: b3N0Q2VudGVyICJbMl0gU2FuZGJveCINCiAgV3JpdGUtSG9zdENlbnRlciAiT25lIGh1Z2UgZ2lm
:: dCAoOTk5OTk5OTkpIG9uY2UgcGVyIHNhdmUiDQogIFdyaXRlLUJsYW5rDQogIFdyaXRlLUhvc3RD
:: ZW50ZXIgIlszXSBDdXN0b20iDQogIFdyaXRlLUhvc3RDZW50ZXIgIlBpY2sgeW91ciBvd24gYW1v
:: dW50IGFuZCBob3cgb2Z0ZW4iDQogIFdyaXRlLUJsYW5rDQogIFdyaXRlLUhvc3RDZW50ZXIgIls0
:: XSBCYWNrIHRvIG1haW4gbWVudSINCiAgV3JpdGUtQmxhbmsNCiAgV3JpdGUtSG9zdENlbnRlciAi
:: UHJlc3MgMSwgMiwgMywgb3IgNDoiDQp9DQoNCmZ1bmN0aW9uIFdhaXQtRm9yTWVudUNob2ljZShb
:: c2NyaXB0YmxvY2tdJFJlZHJhdykgew0KICAmICRSZWRyYXcNCiAgd2hpbGUgKCR0cnVlKSB7DQog
:: ICAgJHNpemUgPSBHZXQtQ29uc29sZVdpZHRoSGVpZ2h0DQogICAgaWYgKFtpbnRdJHNpemUuV2lk
:: dGggLW5lICRzY3JpcHQ6Q29uc29sZVdpZHRoIC1vciBbaW50XSRzaXplLkhlaWdodCAtbmUgJHNj
:: cmlwdDpDb25zb2xlSGVpZ2h0KSB7DQogICAgICAmICRSZWRyYXcNCiAgICB9DQogICAgaWYgKCRI
:: b3N0LlVJLlJhd1VJLktleUF2YWlsYWJsZSkgew0KICAgICAgJGtleSA9ICRIb3N0LlVJLlJhd1VJ
:: LlJlYWRLZXkoIk5vRWNobyxJbmNsdWRlS2V5RG93biIpDQogICAgICBzd2l0Y2ggKCRrZXkuQ2hh
:: cmFjdGVyKSB7DQogICAgICAgICIxIiB7IGV4aXQgMSB9DQogICAgICAgICIyIiB7IGV4aXQgMiB9
:: DQogICAgICAgICIzIiB7IGV4aXQgMyB9DQogICAgICAgICI0IiB7IGV4aXQgNCB9DQogICAgICB9
:: DQogICAgfQ0KICAgIFN0YXJ0LVNsZWVwIC1NaWxsaXNlY29uZHMgMTIwDQogIH0NCn0NCg0KaWYg
:: KCRNZW51IC1lcSAiTWFpbiIpIHsNCiAgV2FpdC1Gb3JNZW51Q2hvaWNlIHsgRHJhdy1NYWluTWVu
:: dSB9DQp9DQoNCmlmICgkTWVudSAtZXEgIkJ1Y2tzIikgew0KICBXYWl0LUZvck1lbnVDaG9pY2Ug
:: eyBEcmF3LUJ1Y2tzTWVudSB9DQp9DQo=
:: FILE ui_line.ps1
:: IyBTaW5nbGUgY2VudGVyZWQgbGluZSBoZWxwZXIgKHNhbWUgZm9ybXVsYSBhcyBsYXVuY2hlcl91
:: aS5wczEpLg0KcGFyYW0oDQogIFtQYXJhbWV0ZXIoTWFuZGF0b3J5ID0gJHRydWUpXQ0KICBbVmFs
:: aWRhdGVTZXQoIlllbGxvdyIsICJSZWQiLCAiQmxhbmsiKV0NCiAgW3N0cmluZ10kTW9kZSwNCiAg
:: W3N0cmluZ10kVGV4dCA9ICIiDQopDQoNCmZ1bmN0aW9uIEdldC1Db25zb2xlV2lkdGggew0KICB0
:: cnkgew0KICAgICR3ID0gW2ludF0kSG9zdC5VSS5SYXdVSS5XaW5kb3dTaXplLldpZHRoDQogICAg
:: aWYgKCR3IC1nZSA0MCkgeyByZXR1cm4gJHcgfQ0KICB9IGNhdGNoIHsgfQ0KICAkY29kZSA9IEAi
:: DQp1c2luZyBTeXN0ZW07DQp1c2luZyBTeXN0ZW0uUnVudGltZS5JbnRlcm9wU2VydmljZXM7DQpw
:: dWJsaWMgc3RhdGljIGNsYXNzIENvblN6TGluZSB7DQogIFtEbGxJbXBvcnQoImtlcm5lbDMyLmRs
:: bCIsIFNldExhc3RFcnJvciA9IHRydWUsIENoYXJTZXQgPSBDaGFyU2V0LlVuaWNvZGUpXQ0KICBw
:: dWJsaWMgc3RhdGljIGV4dGVybiBJbnRQdHIgQ3JlYXRlRmlsZVcoc3RyaW5nIGYsIHVpbnQgYSwg
:: dWludCBzLCBJbnRQdHIgcCwgdWludCBkLCB1aW50IHQsIEludFB0ciBoKTsNCiAgW1N0cnVjdExh
:: eW91dChMYXlvdXRLaW5kLlNlcXVlbnRpYWwpXQ0KICBwdWJsaWMgc3RydWN0IENPT1JEIHsgcHVi
:: bGljIHNob3J0IFg7IHB1YmxpYyBzaG9ydCBZOyB9DQogIFtTdHJ1Y3RMYXlvdXQoTGF5b3V0S2lu
:: ZC5TZXF1ZW50aWFsKV0NCiAgcHVibGljIHN0cnVjdCBTTUFMTF9SRUNUIHsgcHVibGljIHNob3J0
:: IExlZnQ7IHB1YmxpYyBzaG9ydCBUb3A7IHB1YmxpYyBzaG9ydCBSaWdodDsgcHVibGljIHNob3J0
:: IEJvdHRvbTsgfQ0KICBbU3RydWN0TGF5b3V0KExheW91dEtpbmQuU2VxdWVudGlhbCldDQogIHB1
:: YmxpYyBzdHJ1Y3QgQ1NCSSB7DQogICAgcHVibGljIENPT1JEIFNpemU7IHB1YmxpYyBDT09SRCBD
:: dXJzb3I7IHB1YmxpYyBzaG9ydCBBdHRyczsgcHVibGljIFNNQUxMX1JFQ1QgV2luOyBwdWJsaWMg
:: Q09PUkQgTWF4Ow0KICB9DQogIFtEbGxJbXBvcnQoImtlcm5lbDMyLmRsbCIsIFNldExhc3RFcnJv
:: ciA9IHRydWUpXQ0KICBwdWJsaWMgc3RhdGljIGV4dGVybiBib29sIEdldENvbnNvbGVTY3JlZW5C
:: dWZmZXJJbmZvKEludFB0ciBoLCBvdXQgQ1NCSSBpbmZvKTsNCiAgcHVibGljIHN0YXRpYyBpbnQg
:: R2V0V2lkdGgoKSB7DQogICAgSW50UHRyIGggPSBDcmVhdGVGaWxlVygiQ09OT1VUJCIsIDB4ODAw
:: MDAwMDAgfCAweDQwMDAwMDAwLCAyLCBJbnRQdHIuWmVybywgMywgMCwgSW50UHRyLlplcm8pOw0K
:: ICAgIGlmIChoID09IEludFB0ci5aZXJvIHx8IGggPT0gbmV3IEludFB0cigtMSkpIHJldHVybiA4
:: MDsNCiAgICBDU0JJIGk7DQogICAgaWYgKCFHZXRDb25zb2xlU2NyZWVuQnVmZmVySW5mbyhoLCBv
:: dXQgaSkpIHJldHVybiA4MDsNCiAgICBpbnQgdyA9IGkuV2luLlJpZ2h0IC0gaS5XaW4uTGVmdCAr
:: IDE7DQogICAgcmV0dXJuICh3IDwgNDApID8gODAgOiB3Ow0KICB9DQp9DQoiQA0KICB0cnkgeyBB
:: ZGQtVHlwZSAtVHlwZURlZmluaXRpb24gJGNvZGUgLUVycm9yQWN0aW9uIFN0b3AgfCBPdXQtTnVs
:: bCB9IGNhdGNoIHsgfQ0KICB0cnkgeyByZXR1cm4gW0NvblN6TGluZV06OkdldFdpZHRoKCkgfSBj
:: YXRjaCB7IHJldHVybiA4MCB9DQp9DQoNCmlmICgkTW9kZSAtZXEgIkJsYW5rIikgew0KICBXcml0
:: ZS1Ib3N0ICIiDQogIGV4aXQgMA0KfQ0KDQppZiAoW3N0cmluZ106OklzTnVsbE9yRW1wdHkoJFRl
:: eHQpKSB7ICRUZXh0ID0gIiIgfQ0KJHdpZHRoID0gR2V0LUNvbnNvbGVXaWR0aA0KJHBhZCA9IFtN
:: YXRoXTo6TWF4KDAsIFtNYXRoXTo6Rmxvb3IoKCR3aWR0aCAvIDIpIC0gKCRUZXh0Lkxlbmd0aCAv
:: IDIpKSkNCiRjb2xvciA9IGlmICgkTW9kZSAtZXEgIlJlZCIpIHsgW0NvbnNvbGVDb2xvcl06OlJl
:: ZCB9IGVsc2UgeyBbQ29uc29sZUNvbG9yXTo6WWVsbG93IH0NCldyaXRlLUhvc3QgKCgiICIgKiAk
:: cGFkKSArICRUZXh0KSAtRm9yZWdyb3VuZENvbG9yICRjb2xvcg0K
:: END_LAUNCHER_UI_PAYLOAD
