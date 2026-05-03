@echo off
title MyTelescope Server
echo Oprire server existent pe portul 8000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8000 " ^| findstr "LISTENING"') do (
    taskkill /PID %%a /F >nul 2>&1
)
timeout /t 1 /nobreak >nul

echo Pornire server MyTelescope pe http://localhost:8000
echo Proxy Alpaca: http://127.0.0.1:11111
echo.
echo Nu inchide aceasta fereastra cat timp folosesti aplicatia!
echo.

@echo "C:\Program Files\ASCOM\RemoteServer\RemoteServer.exe"

cd /d "C:\Users\F\Documents\2026-04-26_MyTelescope\mytelescope-web"
py "C:\Users\F\Documents\2026-04-26_MyTelescope\mytelescope-web\server.py"
if errorlevel 1 python "C:\Users\F\Documents\2026-04-26_MyTelescope\mytelescope-web\server.py"
pause
