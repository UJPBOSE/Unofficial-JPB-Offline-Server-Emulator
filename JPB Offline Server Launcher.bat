@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Unofficial Jurassic Park Builder - Offline Server
cd /d "%~dp0"
color 07

REM Folder names with parentheses (e.g. "New folder (3)") break CMD IF/FOR parsing.
REM Prefer an 8.3 short path; if unavailable, map a temporary drive letter with SUBST.
set "ROOT=%CD%"
set "SUBST_DRIVE="
for %%I in (".") do set "ROOT=%%~sI"
if not defined ROOT set "ROOT=%CD%"
if "!ROOT:~-1!"=="\" set "ROOT=!ROOT:~0,-1!"
REM Map a drive letter when the folder path has spaces or parentheses.
set "NEED_SUBST="
echo "!CD!" | find " " >nul
if not errorlevel 1 set "NEED_SUBST=1"
echo "!CD!" | find "(" >nul
if not errorlevel 1 set "NEED_SUBST=1"
echo "!CD!" | find ")" >nul
if not errorlevel 1 set "NEED_SUBST=1"
if defined NEED_SUBST (
  for %%D in (J K L M N O P Q R S T U V W X Y Z) do (
    if not defined SUBST_DRIVE if not exist "%%D:\" (
      subst %%D: "!CD!" >nul 2>&1
      if exist "%%D:\" (
        set "SUBST_DRIVE=%%D:"
        set "ROOT=%%D:"
        cd /d "%%D:\"
      )
    )
  )
)

set "SERVER_SCRIPT=JPB_Offline_Server_Emulator.py"
set "SETTINGS_FILE=!ROOT!\launcher_settings.ini"
set "PYTHON_EXE="
call :load_settings
call :ensure_ui_files

:main_menu
call :describe_bucks_mode
powershell -NoProfile -ExecutionPolicy Bypass -File "!ROOT!\launcher_ui.ps1" -Menu Main -BucksDescription "!BUCKS_DESCRIPTION!"
set "MENU_CHOICE=!ERRORLEVEL!"
ver >nul
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
powershell -NoProfile -ExecutionPolicy Bypass -File "!ROOT!\ui_line.ps1" -Mode Blank
exit /b 0

:yellow
powershell -NoProfile -ExecutionPolicy Bypass -File "!ROOT!\ui_line.ps1" -Mode Yellow -Text "!UITEXT!"
exit /b 0

:red
powershell -NoProfile -ExecutionPolicy Bypass -File "!ROOT!\ui_line.ps1" -Mode Red -Text "!UITEXT!"
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
if exist "!ROOT!\launcher_ui.ps1" if exist "!ROOT!\ui_line.ps1" if exist "!ROOT!\resolve_python.cmd" exit /b 0
echo.
echo Missing launcher files next to this .bat:
echo   launcher_ui.ps1
echo   ui_line.ps1
echo   resolve_python.cmd
echo.
echo Download the full project folder from GitHub (not only the .bat file).
echo.
pause
exit 1


:bucks_options
call :describe_bucks_mode
powershell -NoProfile -ExecutionPolicy Bypass -File "!ROOT!\launcher_ui.ps1" -Menu Bucks -BucksDescription "!BUCKS_DESCRIPTION!"
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
call "!ROOT!\resolve_python.cmd"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
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
call :banner
call "!ROOT!\resolve_python.cmd"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
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
"!PYTHON_EXE!" "!ROOT!\patch_manifest_ip.py" "!MANIFEST_IP!"
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
call "!ROOT!\resolve_python.cmd"
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
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
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object { $_.Name -like 'python*.exe' -and $_.CommandLine -like '*JPB_Offline_Server_Emulator.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }"

call :detect_lan_ip
ver >nul
if defined LAN_IP (
  call :blank
  set "UITEXT=Your PC address: !LAN_IP!"
  call :yellow
  set "UITEXT=Game should connect to this PC on your home network."
  call :yellow
)

call :ensure_local_generated_files
set "RC=!ERRORLEVEL!"
if not "!RC!"=="0" (
  call :blank
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
if not defined MAIL_POLICY set "MAIL_POLICY=legit"
if not defined MAIL_AMOUNT set "MAIL_AMOUNT=5"
if /I not "!MAIL_POLICY!"=="legit" if /I not "!MAIL_POLICY!"=="sandbox_once" if /I not "!MAIL_POLICY!"=="per_login" if /I not "!MAIL_POLICY!"=="daily" set "MAIL_POLICY=legit"
call :blank
set "UITEXT=Starting the offline server..."
call :yellow
set "UITEXT=Leave this window open while you play."
call :yellow
set "UITEXT=Press Ctrl+C here when you want to stop."
call :yellow
call :blank
set "UITEXT=Live server log below (ports, logins, saves):"
call :yellow
call :blank
echo.
"!PYTHON_EXE!" -u "!SERVER_SCRIPT!" --host 0.0.0.0 --game-services-mode generic --composite-profile savegame --mail-mode hardcash --hardcash-gift-policy "!MAIL_POLICY!" --hardcash-gift-amount "!MAIL_AMOUNT!" --friend-mode random_user_stub --post-login-push online_options !ADB_ARGS!
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
  cls
  call :banner
  call :blank
  set "UITEXT=Could not detect your PC's network address."
  call :yellow
  set "UITEXT=Use menu [2] First-time setup and type your IPv4 manually,"
  call :yellow
  set "UITEXT=or connect to Wi-Fi / Ethernet and try again."
  call :yellow
  exit /b 1
)
if not exist "!ROOT!\cache_files\" (
  cls
  call :banner
  call :blank
  set "UITEXT=Missing cache_files folder."
  call :yellow
  set "UITEXT=Put your own cache packs in cache_files, then try again."
  call :yellow
  exit /b 1
)
set "HAVE_PACKS="
for %%F in ("!ROOT!\cache_files\*.dab" "!ROOT!\cache_files\*.dhr" "!ROOT!\cache_files\*.dsb") do (
  if exist "%%~fF" set "HAVE_PACKS=1"
)
set "PATCH_EXTRA="
if not defined HAVE_PACKS (
  if exist "!ROOT!\fixed_manifest.json" if exist "!ROOT!\onlineoptions" (
    call :blank
    set "UITEXT=No cache packs found. Using your existing connection files."
    call :yellow
    set "PATCH_EXTRA=--ip-only"
  ) else (
    cls
    call :banner
    call :blank
    set "UITEXT=No game cache packs were found."
    call :yellow
    set "UITEXT=Put your .dab / .dhr / .dsb files in the cache_files folder,"
    call :yellow
    set "UITEXT=then use [2] First-time setup, or press [1] again."
    call :yellow
    exit /b 1
  )
)
call :blank
set "UITEXT=Checking connection files for !LAN_IP! ..."
call :yellow
"!PYTHON_EXE!" "!ROOT!\patch_manifest_ip.py" "!LAN_IP!" !PATCH_EXTRA!
if errorlevel 1 (
  cls
  call :banner
  call :blank
  set "UITEXT=Could not create connection files."
  call :yellow
  set "UITEXT=Make sure cache_files has your .dab / .dhr / .dsb packs,"
  call :yellow
  set "UITEXT=then try [2] First-time setup."
  call :yellow
  exit /b 1
)
exit /b 0


:detect_lan_ip
set "LAN_IP="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -Command "$ip=(Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1 -ExpandProperty IPv4Address | Select-Object -First 1 -ExpandProperty IPAddress); if($ip){$ip}"`) do set "LAN_IP=%%I"
exit /b 0

:exit_launcher
if defined SUBST_DRIVE subst !SUBST_DRIVE! /d >nul 2>&1
endlocal
exit /b 0


