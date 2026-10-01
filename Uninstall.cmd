@echo off
chcp 65001 >nul
title REAPER FL Workflow Uninstaller
set "SCRIPT=%~dp0Uninstall.ps1"
if /I "%~nx0"=="ReaperFLWorkflow-Uninstall.cmd" set "SCRIPT=%~dp0ReaperFLWorkflow-Uninstall.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
echo.
pause
