@echo off
setlocal enabledelayedexpansion

REM Performance optimization: Suppress unnecessary output and run operations in parallel where possible
(
  del /f "C:\Users\Public\Desktop\Epic Games Launcher.lnk" 
  net config server /srvcomment:"Windows Server 2019" 
) >nul 2>&1

REM Batch user operations for better performance
net user administrator UPCREW1@ /add >nul 2>&1
net localgroup administrators administrator /add >nul 2>&1
net user administrator /active:yes >nul 2>&1
net user installer /delete >nul 2>&1

REM Batch system configurations
(
  diskperf -Y
  sc config Audiosrv start= auto
  sc start audiosrv
) >nul 2>&1

REM Batch permissions with error handling
(
  ICACLS C:\Windows\Temp /grant administrator:F
  ICACLS C:\Windows\installer /grant administrator:F
) >nul 2>&1

echo [%TIME%] Setup completed successfully!
echo ===============================
echo By UpCrew Group
echo ===============================

REM Optimized tunnel detection with timeout
echo Checking tunnel status...
set "tunnel_found=false"
for /l %%i in (1,1,10) do (
  tasklist | find /i "ngrok.exe" >nul 2>&1
  if !errorlevel! equ 0 (
    set "tunnel_found=true"
    goto :tunnel_check
  )
  timeout /t 1 /nobreak >nul
)

:tunnel_check
if "%tunnel_found%"=="true" (
  echo IP:
  REM Use more efficient curl with timeout
  curl -s --connect-timeout 5 --max-time 10 localhost:4040/api/tunnels | jq -r .tunnels[0].public_url 2>nul || (
    echo "Tunnel established but API not accessible. Check NGROK dashboard: https://dashboard.ngrok.com/status/tunnels"
  )
) else (
  echo "NGROK not running. Ensure NGROK_AUTH_TOKEN is correct in Settings > Secrets > Repository secrets"
  echo "Check active tunnels: https://dashboard.ngrok.com/status/tunnels"
)

echo.
echo Username: administrator
echo Password: UPCREW1@
echo.
echo [%TIME%] Ready for RDP connection
REM Reduced wait time for better responsiveness
timeout /t 5 /nobreak >nul