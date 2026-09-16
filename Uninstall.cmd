@echo off
chcp 65001 >nul
title REAPER FL Workflow Uninstaller
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
echo.
pause
