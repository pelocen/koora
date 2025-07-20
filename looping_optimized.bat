@echo off
setlocal enabledelayedexpansion

REM Optimized monitoring loop with intelligent checks
echo UpCrew Group - Optimized Monitoring
echo ===================================

:init_check
REM Check NGROK status with timeout to avoid hanging
tasklist | find /i "ngrok.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIME%] ERROR: NGROK not running!
    echo Ensure NGROK_AUTH_TOKEN is correct in Settings ^> Secrets ^> Repository secrets
    echo Or check if tunnel is already connected: https://dashboard.ngrok.com/status/tunnels
    echo.
    echo Retrying in 30 seconds...
    timeout /t 30 /nobreak >nul
    goto init_check
)

echo [%TIME%] NGROK tunnel confirmed active
echo [%TIME%] Starting optimized monitoring...

:monitor_loop
REM Efficient monitoring with reduced frequency
set /a "counter=0"

:check_cycle
set /a "counter+=1"

REM Check every 30 seconds instead of continuous ping
timeout /t 30 /nobreak >nul

REM Verify NGROK is still running
tasklist | find /i "ngrok.exe" >nul 2>&1
if %errorlevel% neq 0 (
    echo [%TIME%] WARNING: NGROK process terminated unexpectedly!
    echo Attempting to restart monitoring...
    goto init_check
)

REM Clear screen every 10 cycles (5 minutes) to prevent clutter
if !counter! geq 10 (
    cls
    echo UpCrew Group - Optimized Monitoring
    echo ===================================
    echo [%TIME%] System healthy - NGROK tunnel active
    echo Monitor cycles completed: !counter!
    echo.
    set /a "counter=0"
) else (
    REM Just show a heartbeat without clearing
    echo [%TIME%] Heartbeat !counter! - Tunnel active
)

goto check_cycle