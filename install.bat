@echo off
setlocal
if /I "%~1"=="--no-pause" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -NonInteractive -GitHubOwner "%~2"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -GitHubOwner "%~1"
)
set "result=%errorlevel%"
if not "%result%"=="0" echo La instalacion fallo. Revisa el mensaje anterior.
if /I not "%~1"=="--no-pause" pause
exit /b %result%