@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Jurassic Park Builder Offline Server Emulator
cd /d "%~dp0"

set "SERVER_SCRIPT=JPB_Offline_Server_Emulator.py"
set "SETTINGS_FILE=%~dp0launcher_settings.ini"
set "PYTHON_EXE="
call :load_settings

:main_menu
cls
call :banner
call :describe_bucks_mode
echo.
echo  Bucks mode: !BUCKS_DESCRIPTION!
echo.
echo  [1] Play
echo  [2] Generate / Patch Manifest
echo  [3] Options
echo  [4] Exit
echo.
choice /C 1234 /N /M "Select an option: "
set "MENU_CHOICE=!ERRORLEVEL!"
if "!MENU_CHOICE!"=="4" goto exit_launcher
if "!MENU_CHOICE!"=="3" goto bucks_options
if "!MENU_CHOICE!"=="2" goto patch_manifest
if "!MENU_CHOICE!"=="1" goto play
goto main_menu

:banner
color 0C
echo.
echo =========================================
echo              UNOFFICIAL
echo         JURASSIC PARK BUILDER
echo        OFFLINE SERVER EMULATOR
echo =========================================
exit /b 0

:describe_bucks_mode
if /I "!BUCKS_MODE!"=="legit" (
  set "BUCKS_DESCRIPTION=Legit - 5 daily plus 25 every 7 days"
  exit /b 0
)
if /I "!BUCKS_MODE!"=="sandbox" (
  set "BUCKS_DESCRIPTION=Sandbox - 99999999 once per save"
  exit /b 0
)
if /I "!CUSTOM_FREQUENCY!"=="daily" (
  set "BUCKS_DESCRIPTION=Custom - !CUSTOM_AMOUNT! every 24 hours"
) else (
  set "BUCKS_DESCRIPTION=Custom - !CUSTOM_AMOUNT! each new game login"
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

:bucks_options
cls
call :banner
call :describe_bucks_mode
echo.
echo  Current: !BUCKS_DESCRIPTION!
echo.
echo  [1] Legit play     - 5 bucks every 24 hours and 25 every 7 days
echo  [2] Sandbox        - 99999999 bucks once per save
echo  [3] Custom         - choose amount and login/daily frequency
echo  [4] Back
echo.
choice /C 1234 /N /M "Select a bucks option: "
set "OPTION_CHOICE=!ERRORLEVEL!"
if "!OPTION_CHOICE!"=="4" goto main_menu
if "!OPTION_CHOICE!"=="3" goto custom_bucks
if "!OPTION_CHOICE!"=="2" (
  set "BUCKS_MODE=sandbox"
  call :save_settings
  echo.
  echo Sandbox bucks selected. The one-time claim persists in the save.
  pause
  goto main_menu
)
if "!OPTION_CHOICE!"=="1" (
  set "BUCKS_MODE=legit"
  call :save_settings
  echo.
  echo Legit bucks selected.
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
echo.
set "CUSTOM_INPUT="
set /p "CUSTOM_INPUT=Enter bucks amount (1-2000000000): "
set "AMOUNT_TO_VALIDATE=!CUSTOM_INPUT!"
call :validate_amount
if not "!VALID_AMOUNT!"=="1" (
  echo Invalid amount. Enter digits only, from 1 through 2000000000.
  pause
  goto custom_bucks
)
echo.
echo  [1] Each time the game makes a new server login
echo  [2] Once every 24 hours
choice /C 12 /N /M "Select frequency: "
if errorlevel 2 (
  set "CUSTOM_FREQUENCY=daily"
) else (
  set "CUSTOM_FREQUENCY=per_login"
)
set "CUSTOM_AMOUNT=!CUSTOM_INPUT!"
set "BUCKS_MODE=custom"
call :save_settings
echo.
echo Custom bucks settings saved.
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
call :resolve_python
if errorlevel 1 (
  pause
  goto main_menu
)
call :detect_lan_ip
echo.
if defined LAN_IP echo Detected LAN IPv4: !LAN_IP!
set "MANIFEST_IP="
set /p "MANIFEST_IP=Enter the PC IPv4 address for the manifest: "
if not defined MANIFEST_IP if defined LAN_IP set "MANIFEST_IP=!LAN_IP!"
if not defined MANIFEST_IP (
  echo No IPv4 address was entered.
  pause
  goto main_menu
)
echo.
echo Building local fixed_manifest.json from cache_files\ and
echo onlineoptions from built-in defaults when needed.
echo.
"!PYTHON_EXE!" "%~dp0patch_manifest_ip.py" "!MANIFEST_IP!"
set "PATCH_EXIT=!ERRORLEVEL!"
echo.
if "!PATCH_EXIT!"=="0" (
  echo Manifest / onlineoptions generate-or-patch completed.
) else (
  echo Manifest / onlineoptions generate-or-patch failed with exit code !PATCH_EXIT!.
)
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
    echo Invalid saved custom amount. Reverting to Legit mode.
    set "BUCKS_MODE=legit"
    set "CUSTOM_AMOUNT=5"
    set "CUSTOM_FREQUENCY=daily"
    call :save_settings
  )
)

echo.
echo Stopping an existing emulator server process...
powershell -NoProfile -Command "for ($pass = 0; $pass -lt 3; $pass++) { Get-CimInstance Win32_Process | Where-Object { $_.Name -like 'python*.exe' -and $_.CommandLine -like '*JPB_Offline_Server_Emulator.py*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }; Start-Sleep -Milliseconds 250 }"
echo Stopping any old listener on ports 80, 9933, and 9943...
for %%P in (80 9933 9943) do (
  for /f "tokens=5" %%A in ('netstat -ano ^| findstr /R /C:":%%P .*LISTENING"') do taskkill /F /PID %%A >nul 2>&1
)

call :detect_lan_ip
if defined LAN_IP echo LAN server address: http://!LAN_IP!/  SFS: !LAN_IP!:9933  Assets: !LAN_IP!:9943

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
echo Bucks mode: !BUCKS_DESCRIPTION!

set "ADB_EXE="
set "ADB_SERIAL="
set "ADB_ARGS="
echo.
choice /C YN /N /M "Use BlueStacks ADB for logcat and clock sync? [Y/N] "
if errorlevel 2 (
  echo Starting without BlueStacks ADB, logcat, or emulator clock sync.
  goto start_server
)
if exist "C:\Program Files\BlueStacks_nxt\HD-Adb.exe" set "ADB_EXE=C:\Program Files\BlueStacks_nxt\HD-Adb.exe"
if not defined ADB_EXE if exist "C:\Program Files\BlueStacks\HD-Adb.exe" set "ADB_EXE=C:\Program Files\BlueStacks\HD-Adb.exe"
if not defined ADB_EXE if exist "C:\Program Files (x86)\BlueStacks\HD-Adb.exe" set "ADB_EXE=C:\Program Files (x86)\BlueStacks\HD-Adb.exe"
if not defined ADB_EXE (
  echo BlueStacks ADB was not found. Starting without local logcat or clock sync.
  goto start_server
)
"!ADB_EXE!" connect 127.0.0.1:5555 >nul 2>&1
for /f "usebackq delims=" %%S in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$adb=$env:ADB_EXE; $preferred=@('emulator-5554','127.0.0.1:5555'); $lines=& $adb devices 2>$null; $devices=@(); foreach($line in $lines){ if($line -match '^(\S+)\s+device$'){ $devices += $matches[1] } }; foreach($p in $preferred){ if($devices -contains $p){ Write-Output $p; exit 0 } }; if($devices.Count -gt 0){ Write-Output $devices[0] }"`) do set "ADB_SERIAL=%%S"
if not defined ADB_SERIAL (
  echo No online ADB device was found. Starting without local logcat or clock sync.
  goto start_server
)
echo Using ADB: !ADB_EXE!
echo Using ADB serial: !ADB_SERIAL!
set "ADB_ARGS=--adb-logcat --adb-path "!ADB_EXE!" --adb-serial "!ADB_SERIAL!" --sync-adb-clock --adb-clock-max-drift-seconds 5 --adb-clock-sync-interval-seconds 60 --adb-timezone auto"

:start_server
echo.
echo Starting Jurassic Park Builder Offline Server Emulator...
"!PYTHON_EXE!" "!SERVER_SCRIPT!" --host 0.0.0.0 --game-services-mode generic --composite-profile savegame --mail-mode hardcash --hardcash-gift-policy "!MAIL_POLICY!" --hardcash-gift-amount "!MAIL_AMOUNT!" --friend-mode random_user_stub --post-login-push online_options !ADB_ARGS! %*
set "SERVER_EXIT=!ERRORLEVEL!"
echo.
echo Server stopped with exit code !SERVER_EXIT!.
pause
goto main_menu

:ensure_local_generated_files
:: Build gitignored fixed_manifest.json + onlineoptions on Play when missing,
:: or refresh the manifest IP to the detected LAN address.
if not defined LAN_IP (
  echo Could not detect a LAN IPv4 address. Use menu [2] to enter one manually,
  echo or connect to a network and try Play again.
  exit /b 1
)
if not exist "%~dp0cache_files\" (
  echo Missing cache_files\ folder. Put your own cache packs there first.
  exit /b 1
)
echo.
echo Ensuring local fixed_manifest.json and onlineoptions for !LAN_IP! ...
"!PYTHON_EXE!" "%~dp0patch_manifest_ip.py" "!LAN_IP!"
if errorlevel 1 (
  echo Failed to generate or patch local manifest / onlineoptions.
  echo Make sure cache_files\ has your .dab/.dhr/.dsb packs.
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
  echo.
  echo Python was not found. Install Python or add a real python.exe to PATH.
  exit /b 1
)
"!PYTHON_EXE!" -c "import sys; ok=sys.version_info[0] == 3 and sys.version_info[1] in range(10, 100); raise SystemExit(0 if ok else 1)" >nul 2>&1
if errorlevel 1 (
  echo Python 3.10 or newer is required: !PYTHON_EXE!
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
