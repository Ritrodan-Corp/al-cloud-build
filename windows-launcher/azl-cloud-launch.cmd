@echo off
setlocal EnableExtensions

set "PROJECT=project-97e3d26a-3ba2-4579-b03"
set "ZONE=us-central1-a"
set "VM=azl-android-arm64-01"
set "LOCAL_PORT=8766"
set "URL=http://127.0.0.1:%LOCAL_PORT%/"
set "STATUS_URL=%URL%api/status"
set "STATE_DIR=%LOCALAPPDATA%\AzurLaneCloud"
set "LOG=%STATE_DIR%\tunnel.log"

if not exist "%STATE_DIR%" mkdir "%STATE_DIR%" >nul 2>&1

where gcloud.cmd >nul 2>&1
if errorlevel 1 (
  >"%LOG%" echo Google Cloud CLI was not found on PATH.
  >>"%LOG%" echo Install or repair gcloud, then run Azur Lane Cloud again.
  start "" notepad.exe "%LOG%"
  exit /b 1
)

call :is_ready
if not errorlevel 1 goto open_browser

>"%LOG%" echo [%date% %time%] Starting Azur Lane Cloud IAP/SSH tunnel.
start "Azur Lane Cloud Tunnel" /min cmd.exe /d /c ""gcloud.cmd" compute ssh "%VM%" --project="%PROJECT%" --zone="%ZONE%" --tunnel-through-iap --ssh-flag="-N" --ssh-flag="-L %LOCAL_PORT%:127.0.0.1:%LOCAL_PORT%" >> "%LOG%" 2>&1"

for /l %%I in (1,1,45) do (
  call :is_ready
  if not errorlevel 1 goto open_browser
  timeout /t 1 /nobreak >nul
)

>>"%LOG%" echo.
>>"%LOG%" echo Azur Lane Cloud did not become reachable within 45 seconds.
>>"%LOG%" echo The VM may be off, gcloud authentication may need attention, or the tunnel failed.
start "" notepad.exe "%LOG%"
exit /b 2

:open_browser
start "" "%URL%"
exit /b 0

:is_ready
curl.exe --silent --fail --max-time 1 "%STATUS_URL%" >nul 2>&1
exit /b %errorlevel%
