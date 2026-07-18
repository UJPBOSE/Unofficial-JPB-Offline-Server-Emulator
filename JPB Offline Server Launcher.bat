@echo off
REM Thin wrapper only. All launcher logic lives in launcher_main.ps1 so folder
REM names with spaces or parentheses cannot break CMD IF/FOR parsing.
chcp 65001 >nul
title Unofficial Jurassic Park Builder - Offline Server
color 07
cd /d "%~dp0"
if not exist ".\launcher_main.ps1" goto missing_main
REM Use a relative -File path after cd so spaces in the folder name cannot split argv.
powershell -NoProfile -ExecutionPolicy Bypass -File ".\launcher_main.ps1"
set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" pause
exit /b %EXITCODE%

:missing_main
echo.
echo Missing launcher_main.ps1 next to this .bat
echo Download the full project folder from GitHub (not only the .bat file).
echo.
pause
exit /b 1
