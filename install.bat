@echo off
chcp 65001 > nul
if /I "%~1"=="--no-pause" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -NonInteractive
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" -GitHubOwner "%~1"
)
if errorlevel 1 (
  echo La instalacion fallo. Revisa el mensaje anterior.
  if "%1" neq "--no-pause" pause
  exit /b 1
)
if "%1" neq "--no-pause" pause
