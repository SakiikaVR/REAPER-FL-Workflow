@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
where cl.exe >nul 2>nul
if not errorlevel 1 goto build
"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath > "%TEMP%\reaper-linefont-vsroot.txt"
set /p "VSROOT="<"%TEMP%\reaper-linefont-vsroot.txt"
del "%TEMP%\reaper-linefont-vsroot.txt" >nul 2>nul
if not defined VSROOT (
  echo Visual Studio C++ Build Tools was not found.
  exit /b 1
)
call "!VSROOT!\VC\Auxiliary\Build\vcvars64.bat"
:build
if not exist reaper_plugin.h powershell.exe -NoProfile -Command "Invoke-WebRequest 'https://www.reaper.fm/sdk/plugin/reaper_plugin.h' -OutFile 'reaper_plugin.h'"
if errorlevel 1 exit /b 1
cl /nologo /utf-8 /std:c++17 /EHsc /O2 /MT /LD LINEFont.cpp /link /OUT:reaper_LINEFont.dll user32.lib gdi32.lib comctl32.lib
if errorlevel 1 exit /b 1
cl /nologo /utf-8 /std:c++17 /EHsc /O2 /MT /DLINEFONT_TEST LINEFont.cpp /Fe:"%CD%\LINEFontTest.exe" /link user32.lib gdi32.lib comctl32.lib
if errorlevel 1 exit /b 1
"%CD%\LINEFontTest.exe"
exit /b %errorlevel%