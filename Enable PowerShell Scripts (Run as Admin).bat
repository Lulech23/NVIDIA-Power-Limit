@echo off
echo.
echo Setting PowerShell script execution policy...
echo.

powershell.exe Set-ExecutionPolicy -Scope "CurrentUser" -ExecutionPolicy "RemoteSigned"
powershell.exe Unblock-File -Path ".\NVIDIA Power Limit.ps1"

echo ... Done!
echo.
pause