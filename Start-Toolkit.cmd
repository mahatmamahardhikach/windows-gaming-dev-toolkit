@echo off
setlocal
where pwsh.exe >nul 2>&1
if %errorlevel% equ 0 (
  pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Toolkit.ps1"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Toolkit.ps1"
)
endlocal
