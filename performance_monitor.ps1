# Performance Monitor for RDP Session
# Monitors CPU, Memory, Network, and Process metrics

param(
    [int]$IntervalSeconds = 30,
    [string]$LogFile = "performance_log.csv",
    [switch]$Continuous = $false
)

function Write-PerformanceLog {
    param($LogEntry)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp,$($LogEntry -join ',')"
    
    Write-Host "[$timestamp] $($LogEntry -join ' | ')"
    Add-Content -Path $LogFile -Value $logLine
}

function Get-SystemMetrics {
    # CPU Usage
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 2 | 
                Select-Object -ExpandProperty CounterSamples | 
                Select-Object -Last 1).CookedValue
    
    # Memory Usage
    $totalMemory = (Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB
    $availableMemory = (Get-Counter "\Memory\Available MBytes").CounterSamples.CookedValue / 1024
    $memoryUsagePercent = [math]::Round((($totalMemory - $availableMemory) / $totalMemory) * 100, 2)
    
    # Network Usage (bytes/sec)
    $networkAdapters = Get-Counter "\Network Interface(*)\Bytes Total/sec" | 
                      Where-Object { $_.CounterSamples.InstanceName -notlike "*Loopback*" -and 
                                    $_.CounterSamples.InstanceName -notlike "*isatap*" }
    $totalNetworkBytes = ($networkAdapters.CounterSamples | Measure-Object CookedValue -Sum).Sum
    
    # Process Information
    $ngrokProcess = Get-Process -Name "ngrok" -ErrorAction SilentlyContinue
    $ngrokMemory = if ($ngrokProcess) { [math]::Round($ngrokProcess.WorkingSet64 / 1MB, 2) } else { 0 }
    $ngrokCpu = if ($ngrokProcess) { $ngrokProcess.CPU } else { 0 }
    
    # Active RDP Sessions
    $rdpSessions = (Get-Process -Name "rdpclip" -ErrorAction SilentlyContinue | Measure-Object).Count
    
    return @{
        CPUPercent = [math]::Round($cpuUsage, 2)
        MemoryPercent = $memoryUsagePercent
        MemoryUsedGB = [math]::Round($totalMemory - $availableMemory, 2)
        NetworkBytesPerSec = [math]::Round($totalNetworkBytes, 0)
        NGROKMemoryMB = $ngrokMemory
        NGROKRunning = $ngrokProcess -ne $null
        RDPSessions = $rdpSessions
        TotalProcesses = (Get-Process | Measure-Object).Count
    }
}

function Test-NGROKTunnel {
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -TimeoutSec 5 -ErrorAction Stop
        $tunnel = $response.tunnels | Where-Object { $_.proto -eq "tcp" } | Select-Object -First 1
        
        if ($tunnel) {
            return @{
                Status = "Active"
                PublicURL = $tunnel.public_url
                Connections = $tunnel.metrics.conns.count
                BytesIn = $tunnel.metrics.http.bytes_in
                BytesOut = $tunnel.metrics.http.bytes_out
            }
        }
    } catch {
        return @{
            Status = "Inactive"
            Error = $_.Exception.Message
        }
    }
    
    return @{ Status = "Unknown" }
}

# Initialize log file
if (!(Test-Path $LogFile)) {
    $headers = "Timestamp,CPU%,Memory%,MemoryGB,NetworkBytes/s,NGROKMemoryMB,NGROKRunning,RDPSessions,TotalProcesses,TunnelStatus,TunnelURL"
    Add-Content -Path $LogFile -Value $headers
}

Write-Host "Performance Monitor Started - Interval: $IntervalSeconds seconds"
Write-Host "Log File: $LogFile"
Write-Host "Press Ctrl+C to stop monitoring"
Write-Host ("-" * 80)

do {
    try {
        $metrics = Get-SystemMetrics
        $tunnelInfo = Test-NGROKTunnel
        
        $logEntry = @(
            $metrics.CPUPercent,
            $metrics.MemoryPercent,
            $metrics.MemoryUsedGB,
            $metrics.NetworkBytesPerSec,
            $metrics.NGROKMemoryMB,
            $metrics.NGROKRunning,
            $metrics.RDPSessions,
            $metrics.TotalProcesses,
            $tunnelInfo.Status,
            $tunnelInfo.PublicURL
        )
        
        Write-PerformanceLog -LogEntry $logEntry
        
        # Performance alerts
        if ($metrics.CPUPercent -gt 80) {
            Write-Warning "High CPU usage detected: $($metrics.CPUPercent)%"
        }
        
        if ($metrics.MemoryPercent -gt 85) {
            Write-Warning "High memory usage detected: $($metrics.MemoryPercent)%"
        }
        
        if (-not $metrics.NGROKRunning) {
            Write-Warning "NGROK process not running!"
        }
        
        if ($tunnelInfo.Status -ne "Active") {
            Write-Warning "NGROK tunnel not active: $($tunnelInfo.Status)"
        }
        
    } catch {
        Write-Error "Error collecting metrics: $($_.Exception.Message)"
    }
    
    if ($Continuous) {
        Start-Sleep -Seconds $IntervalSeconds
    }
    
} while ($Continuous)

Write-Host "Performance monitoring completed. Log saved to: $LogFile"