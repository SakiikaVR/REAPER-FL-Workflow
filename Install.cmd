@echo off
chcp 65001 >nul
title REAPER FL Workflow Installer
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1"
echo.
pause
