@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM Finds a usable Python 3.10+ and returns PYTHON_EXE to the caller.
if defined PYTHON_EXE if exist "!PYTHON_EXE!" goto export_ok
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
if not defined PYTHON_EXE goto export_missing
"!PYTHON_EXE!" -c "import sys; ok=sys.version_info[0] == 3 and sys.version_info[1] in range(10, 100); raise SystemExit(0 if ok else 1)" >nul 2>&1
if errorlevel 1 goto export_old
goto export_ok

:export_missing
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Blank
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Yellow -Text "Python was not found on this PC."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Yellow -Text "Install Python 3 from python.org, then try again."
endlocal & set "PYTHON_EXE=" & exit /b 1

:export_old
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Yellow -Text "Python 3.10 or newer is required."
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0ui_line.ps1" -Mode Yellow -Text "Found: %PYTHON_EXE%"
endlocal & set "PYTHON_EXE=" & exit /b 1

:export_ok
endlocal & set "PYTHON_EXE=%PYTHON_EXE%" & exit /b 0
