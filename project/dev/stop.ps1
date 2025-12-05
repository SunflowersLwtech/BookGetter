#Requires -Version 5.1
<#
.SYNOPSIS
    BookGetter Stop Script - Robust Tomcat shutdown

.DESCRIPTION
    Detects and stops Tomcat service using multiple methods:
    1. Graceful shutdown via catalina.bat
    2. Force terminate Java processes on Tomcat ports
    3. Handle TIME_WAIT port states
    Prioritizes reading paths from 项目技术栈信息.md configuration file.

.PARAMETER Force
    Skip graceful shutdown, force terminate immediately

.PARAMETER Timeout
    Graceful shutdown timeout in seconds (default: 10)

.PARAMETER Help
    Show help information

.EXAMPLE
    .\stop.ps1
    Gracefully stop Tomcat

.EXAMPLE
    .\stop.ps1 -Force
    Force stop Tomcat immediately
#>

[CmdletBinding()]
param(
    [switch]$Force,
    [int]$Timeout = 10,
    [switch]$Help
)

# ==================== Configuration ====================
$Script:VERSION = "1.1.0"
$Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Script:ProjectRoot = Split-Path -Parent $Script:ScriptDir
$Script:BookGetterRoot = Split-Path -Parent $Script:ProjectRoot

# Configuration file path
$Script:ConfigFile = Join-Path $Script:BookGetterRoot "项目技术栈信息.md"

# ==================== Utility Functions ====================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    switch ($Level) {
        "INFO" { Write-Host "[$timestamp] $Message" -ForegroundColor Cyan }
        "SUCCESS" { Write-Host "[$timestamp] [OK] $Message" -ForegroundColor Green }
        "WARNING" { Write-Host "[$timestamp] [!] $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "[$timestamp] [X] $Message" -ForegroundColor Red }
        default { Write-Host "[$timestamp] $Message" }
    }
}

function Write-Banner {
    $banner = @"

+==============================================================+
|                    BookGetter Stop Script                    |
|                      Version $($Script:VERSION)                            |
+==============================================================+

"@
    Write-Host $banner -ForegroundColor Magenta
}

function Show-Help {
    Write-Banner
    Get-Help $MyInvocation.PSCommandPath -Detailed
}

# ==================== Configuration File Reading ====================

function Read-ConfigFile {
    $config = @{
        JavaPath        = $null
        TomcatPath      = $null
        ConfigFileFound = $false
    }
    
    if (-not (Test-Path $Script:ConfigFile)) {
        return $config
    }
    
    $config.ConfigFileFound = $true
    
    try {
        $content = Get-Content $Script:ConfigFile -Encoding UTF8 -Raw
        
        # Extract Tomcat path
        if ($content -match '`([^`]*apache-tomcat-[^`\\]*)`') {
            $config.TomcatPath = $matches[1]
        }
        elseif ($content -match '([A-Z]:\\[^\r\n`]*apache-tomcat-[^\r\n`\\]*)') {
            $config.TomcatPath = $matches[1].Trim()
        }
    }
    catch { }
    
    return $config
}

# ==================== Environment Detection ====================

function Find-CatalinaHome {
    # 1. PRIORITY: Read from configuration file
    $config = Read-ConfigFile
    if ($config.TomcatPath -and (Test-Path "$($config.TomcatPath)\bin\catalina.bat")) {
        Write-Log "Found Tomcat from config: $($config.TomcatPath)" "SUCCESS"
        return $config.TomcatPath
    }
    
    # 2. Check environment variable
    if ($env:CATALINA_HOME -and (Test-Path "$env:CATALINA_HOME\bin\catalina.bat")) {
        return $env:CATALINA_HOME
    }
    
    # 3. Check common paths
    $commonPaths = @(
        "C:\cs\apache-tomcat-*",
        "C:\Program Files\Apache Software Foundation\Tomcat*",
        "C:\apache-tomcat-*",
        "C:\tomcat*",
        "D:\tomcat*",
        "E:\tomcat*",
        "E:\tools\apache-tomcat-*\apache-tomcat-*",
        "E:\tools\apache-tomcat-*",
        "C:\tools\apache-tomcat-*"
    )
    
    foreach ($pattern in $commonPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSIsContainer } |
        Sort-Object Name -Descending | 
        Select-Object -First 1
        if ($found -and (Test-Path "$($found.FullName)\bin\catalina.bat")) {
            return $found.FullName
        }
    }
    
    return $null
}

# ==================== Process Detection ====================

function Get-PortInfo {
    param([int]$Port)
    
    $connections = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    if (-not $connections) {
        return @{ InUse = $false; State = "Free"; PID = $null; ProcessName = $null }
    }
    
    # Get the first connection with a valid owning process
    foreach ($conn in $connections) {
        if ($conn.OwningProcess -gt 0) {
            $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
            return @{
                InUse       = $true
                State       = $conn.State
                PID         = $conn.OwningProcess
                ProcessName = if ($proc) { $proc.ProcessName } else { "Unknown" }
            }
        }
    }
    
    # If all connections have PID 0, it's likely TIME_WAIT state
    $firstConn = $connections | Select-Object -First 1
    return @{
        InUse       = $true
        State       = $firstConn.State
        PID         = 0
        ProcessName = "System (TIME_WAIT)"
    }
}

function Test-TomcatRunning {
    $port8080 = Get-PortInfo -Port 8080
    $port8005 = Get-PortInfo -Port 8005
    
    # Consider running only if there's an actual process (PID > 0)
    $hasActiveProcess = ($port8080.PID -gt 0) -or ($port8005.PID -gt 0)
    
    return @{
        Running  = $hasActiveProcess
        Port8080 = $port8080
        Port8005 = $port8005
    }
}

function Show-TomcatStatus {
    $status = Test-TomcatRunning
    
    Write-Host ""
    Write-Host "  Port Status:" -ForegroundColor Gray
    
    # Port 8080
    $p8080 = $status.Port8080
    Write-Host "    * 8080 (HTTP):     " -NoNewline -ForegroundColor Gray
    if (-not $p8080.InUse) {
        Write-Host "Free" -ForegroundColor Green
    }
    elseif ($p8080.PID -eq 0) {
        Write-Host "TIME_WAIT (will clear soon)" -ForegroundColor Yellow
    }
    else {
        Write-Host "$($p8080.State)" -NoNewline -ForegroundColor Yellow
        Write-Host " - $($p8080.ProcessName) (PID: $($p8080.PID))" -ForegroundColor Gray
    }
    
    # Port 8005
    $p8005 = $status.Port8005
    Write-Host "    * 8005 (Shutdown): " -NoNewline -ForegroundColor Gray
    if (-not $p8005.InUse) {
        Write-Host "Free" -ForegroundColor Green
    }
    elseif ($p8005.PID -eq 0) {
        Write-Host "TIME_WAIT (will clear soon)" -ForegroundColor Yellow
    }
    else {
        Write-Host "$($p8005.State)" -NoNewline -ForegroundColor Yellow
        Write-Host " - $($p8005.ProcessName) (PID: $($p8005.PID))" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    return $status
}

function Get-TomcatProcessIds {
    $pids = @()
    
    @(8080, 8005) | ForEach-Object {
        $port = $_
        $connections = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        foreach ($conn in $connections) {
            if ($conn.OwningProcess -gt 0) {
                $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
                if ($proc -and $proc.ProcessName -eq "java") {
                    $pids += $conn.OwningProcess
                }
            }
        }
    }
    
    return $pids | Sort-Object -Unique
}

# ==================== Stop Functions ====================

function Stop-TomcatGracefully {
    param([string]$CatalinaHome)
    
    Write-Log "Attempting graceful shutdown..."
    
    # Set environment variables for catalina.bat
    $env:CATALINA_HOME = $CatalinaHome
    $env:JAVA_HOME = $env:JAVA_HOME
    
    # If JAVA_HOME not set, try to find it
    if (-not $env:JAVA_HOME) {
        $commonJavaPaths = @(
            "C:\Program Files\Eclipse Adoptium\jdk-*",
            "C:\Program Files\Java\jdk-*"
        )
        foreach ($pattern in $commonJavaPaths) {
            $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
            Where-Object { $_.PSIsContainer } |
            Sort-Object Name -Descending | 
            Select-Object -First 1
            if ($found -and (Test-Path "$($found.FullName)\bin\java.exe")) {
                $env:JAVA_HOME = $found.FullName
                break
            }
        }
    }
    
    $catalinaScript = Join-Path $CatalinaHome "bin\catalina.bat"
    
    try {
        # Run catalina.bat stop with environment set
        $pinfo = New-Object System.Diagnostics.ProcessStartInfo
        $pinfo.FileName = "cmd.exe"
        $pinfo.Arguments = "/c `"$catalinaScript`" stop"
        $pinfo.UseShellExecute = $false
        $pinfo.RedirectStandardOutput = $true
        $pinfo.RedirectStandardError = $true
        $pinfo.CreateNoWindow = $true
        $pinfo.EnvironmentVariables["CATALINA_HOME"] = $CatalinaHome
        if ($env:JAVA_HOME) {
            $pinfo.EnvironmentVariables["JAVA_HOME"] = $env:JAVA_HOME
        }
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $pinfo
        $process.Start() | Out-Null
        $process.WaitForExit(10000) | Out-Null
        
        return $process.ExitCode -eq 0
    }
    catch {
        Write-Log "catalina.bat stop failed: $_" "WARNING"
        return $false
    }
}

function Stop-ProcessByPid {
    param([int]$ProcessId)
    
    try {
        $proc = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | Stop-Process -Force
            Write-Log "Terminated: $($proc.ProcessName) (PID: $ProcessId)" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "Failed to terminate PID $ProcessId : $_" "ERROR"
    }
    return $false
}

function Stop-TomcatForcefully {
    Write-Log "Force stopping Tomcat processes..." "WARNING"
    
    $pids = Get-TomcatProcessIds
    $killed = 0
    
    if ($pids.Count -gt 0) {
        foreach ($pid in $pids) {
            if (Stop-ProcessByPid -ProcessId $pid) {
                $killed++
            }
        }
    }
    else {
        # No Tomcat-specific Java processes found, try to find any Java using our ports
        Write-Log "No Java processes found on Tomcat ports, checking all Java processes..." "WARNING"
        
        $javaProcesses = Get-Process -Name "java" -ErrorAction SilentlyContinue
        if ($javaProcesses) {
            Write-Log "Found $($javaProcesses.Count) Java process(es)" "WARNING"
            foreach ($proc in $javaProcesses) {
                if (Stop-ProcessByPid -ProcessId $proc.Id) {
                    $killed++
                }
            }
        }
        else {
            Write-Log "No Java processes running" "INFO"
        }
    }
    
    return $killed
}

function Wait-ForPortRelease {
    param(
        [int]$Port,
        [int]$TimeoutSeconds
    )
    
    Write-Host "  Waiting for port $Port to be released" -NoNewline -ForegroundColor Gray
    
    $elapsed = 0
    while ($elapsed -lt $TimeoutSeconds) {
        $info = Get-PortInfo -Port $Port
        if (-not $info.InUse -or $info.PID -eq 0) {
            Write-Host " Done" -ForegroundColor Green
            return $true
        }
        
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 1
        $elapsed++
    }
    
    Write-Host " Timeout" -ForegroundColor Yellow
    return $false
}

# ==================== Main ====================

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Banner
    
    # ========== Step 1: Check Status ==========
    Write-Host "[Step 1] Check Tomcat Status" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    # Check config file
    if (Test-Path $Script:ConfigFile) {
        Write-Log "Config file: $Script:ConfigFile" "SUCCESS"
    }
    
    $status = Show-TomcatStatus
    
    if (-not $status.Running) {
        # Check if ports are in TIME_WAIT
        $hasTimeWait = ($status.Port8080.PID -eq 0 -and $status.Port8080.InUse) -or 
        ($status.Port8005.PID -eq 0 -and $status.Port8005.InUse)
        
        if ($hasTimeWait) {
            Write-Log "No active Tomcat process. Ports in TIME_WAIT state will clear automatically (usually 30-120 seconds)." "SUCCESS"
        }
        else {
            Write-Log "Tomcat is not running" "SUCCESS"
        }
        
        Write-Host ""
        Write-Host "  Tip: To start Tomcat, run .\start.ps1" -ForegroundColor Yellow
        Write-Host ""
        return
    }
    
    # ========== Step 2: Stop Tomcat ==========
    Write-Host "[Step 2] Stop Tomcat" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $stopped = $false
    
    if ($Force) {
        $killed = Stop-TomcatForcefully
        $stopped = $killed -gt 0
    }
    else {
        $catalinaHome = Find-CatalinaHome
        
        if ($catalinaHome) {
            Write-Log "CATALINA_HOME: $catalinaHome"
            $gracefulSuccess = Stop-TomcatGracefully -CatalinaHome $catalinaHome
            
            if ($gracefulSuccess) {
                $stopped = Wait-ForPortRelease -Port 8080 -TimeoutSeconds $Timeout
            }
            
            if (-not $stopped) {
                Write-Log "Graceful shutdown failed or timed out, forcing..." "WARNING"
                $killed = Stop-TomcatForcefully
                $stopped = $killed -gt 0
            }
        }
        else {
            Write-Log "CATALINA_HOME not found, forcing stop..." "WARNING"
            $killed = Stop-TomcatForcefully
            $stopped = $killed -gt 0
        }
    }
    
    # Wait a moment for ports to clear
    Start-Sleep -Seconds 2
    
    Write-Host ""
    
    # ========== Step 3: Verify Result ==========
    Write-Host "[Step 3] Verify Stop Result" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $finalStatus = Show-TomcatStatus
    
    if ($finalStatus.Running) {
        Write-Log "Warning: Tomcat may still be running" "WARNING"
        Write-Host ""
        Write-Host "  Tip: Try .\stop.ps1 -Force" -ForegroundColor Yellow
        Write-Host ""
        exit 1
    }
    else {
        # Check for TIME_WAIT
        $hasTimeWait = ($finalStatus.Port8080.PID -eq 0 -and $finalStatus.Port8080.InUse) -or 
        ($finalStatus.Port8005.PID -eq 0 -and $finalStatus.Port8005.InUse)
        
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "                    Tomcat Stopped!                            " -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host ""
        
        if ($hasTimeWait) {
            Write-Host "  Note: Ports in TIME_WAIT will clear in 30-120 seconds" -ForegroundColor Yellow
        }
        
        Write-Host "  Tip: To restart, run .\start.ps1" -ForegroundColor Yellow
        Write-Host "  Tip: To redeploy, run .\deploy.ps1" -ForegroundColor Yellow
        Write-Host ""
    }
}

try {
    Main
}
catch {
    Write-Log "Error: $_" "ERROR"
    exit 1
}
