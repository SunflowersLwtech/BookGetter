#Requires -Version 5.1
<#
.SYNOPSIS
    BookGetter Start Script - Start Tomcat and verify service ready

.DESCRIPTION
    This script auto-detects environment, starts Tomcat server,
    and waits for BookGetter to be fully ready.
    Prioritizes reading paths from 项目技术栈信息.md configuration file.

.PARAMETER Background
    Start Tomcat in background (non-blocking)

.PARAMETER NoHealthCheck
    Skip health check

.PARAMETER Help
    Show help information

.EXAMPLE
    .\start.ps1
    Start Tomcat in foreground (blocks terminal)

.EXAMPLE
    .\start.ps1 -Background
    Start Tomcat in background
#>

[CmdletBinding()]
param(
    [switch]$Background,
    [switch]$NoHealthCheck,
    [switch]$Help
)

# ==================== Configuration ====================
$Script:VERSION = "1.1.0"
$Script:APP_NAME = "BookGetter"
$Script:APP_URL = "http://localhost:8080/BookGetter/"
$Script:HEALTH_CHECK_TIMEOUT = 60
$Script:HEALTH_CHECK_INTERVAL = 2

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
|                   BookGetter Start Script                    |
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

function Find-JavaHome {
    # 1. Check environment variable
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        return $env:JAVA_HOME
    }
    
    # 2. Check common paths
    $commonPaths = @(
        "C:\Program Files\Eclipse Adoptium\jdk-*",
        "C:\Program Files\Java\jdk-*",
        "C:\Program Files\Microsoft\jdk-*",
        "C:\Program Files\Amazon Corretto\jdk*",
        "C:\Program Files\Zulu\zulu-*",
        "C:\Program Files\OpenJDK\jdk-*"
    )
    
    foreach ($pattern in $commonPaths) {
        $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
        Where-Object { $_.PSIsContainer } |
        Sort-Object Name -Descending | 
        Select-Object -First 1
        if ($found -and (Test-Path "$($found.FullName)\bin\java.exe")) {
            return $found.FullName
        }
    }
    
    # 3. Check PATH
    $javaInPath = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaInPath) {
        $javaExe = $javaInPath.Source
        return Split-Path (Split-Path $javaExe)
    }
    
    return $null
}

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

# ==================== Status Detection ====================

function Test-PortInUse {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

function Test-TomcatRunning {
    return (Test-PortInUse 8080) -or (Test-PortInUse 8005)
}

function Get-PortProcess {
    param([int]$Port)
    $connection = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($connection) {
        $process = Get-Process -Id $connection.OwningProcess -ErrorAction SilentlyContinue
        return $process
    }
    return $null
}

function Wait-ForServiceReady {
    Write-Log "Waiting for service to be ready..."
    
    $startTime = Get-Date
    $timeout = $Script:HEALTH_CHECK_TIMEOUT
    $interval = $Script:HEALTH_CHECK_INTERVAL
    
    Write-Host "  Waiting for port 8080..." -NoNewline -ForegroundColor Gray
    while (-not (Test-PortInUse 8080)) {
        $elapsed = ((Get-Date) - $startTime).TotalSeconds
        if ($elapsed -gt $timeout) {
            Write-Host " Timeout" -ForegroundColor Red
            return $false
        }
        Start-Sleep -Seconds 1
        Write-Host "." -NoNewline -ForegroundColor Gray
    }
    Write-Host " Ready" -ForegroundColor Green
    
    Write-Host "  Waiting for app response..." -NoNewline -ForegroundColor Gray
    $retries = 0
    $maxRetries = [math]::Ceiling($timeout / $interval)
    
    while ($retries -lt $maxRetries) {
        try {
            $response = Invoke-WebRequest -Uri $Script:APP_URL -UseBasicParsing -TimeoutSec 5 -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Host " Ready" -ForegroundColor Green
                return $true
            }
        }
        catch { }
        
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds $interval
        $retries++
    }
    
    Write-Host " Timeout" -ForegroundColor Yellow
    Write-Log "App may still be starting, please check manually" "WARNING"
    return $false
}

# ==================== Main ====================

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Banner
    
    # ========== Step 1: Environment Detection ==========
    Write-Host "[Step 1] Environment Detection" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    # Check config file
    if (Test-Path $Script:ConfigFile) {
        Write-Log "Config file: $Script:ConfigFile" "SUCCESS"
    }
    
    $javaHome = Find-JavaHome
    if (-not $javaHome) {
        Write-Log "Java not found, run deploy.ps1 for installation guide" "ERROR"
        exit 1
    }
    Write-Log "JAVA_HOME: $javaHome" "SUCCESS"
    
    $catalinaHome = Find-CatalinaHome
    if (-not $catalinaHome) {
        Write-Log "Tomcat not found, run deploy.ps1 for installation guide" "ERROR"
        exit 1
    }
    Write-Log "CATALINA_HOME: $catalinaHome" "SUCCESS"
    
    $dataDir = Join-Path $Script:ProjectRoot "data"
    Write-Log "BOOKGETTER_DATA_DIR: $dataDir"
    
    Write-Host ""
    
    # ========== Step 2: Check Port Status ==========
    Write-Host "[Step 2] Check Port Status" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    if (Test-TomcatRunning) {
        $process8080 = Get-PortProcess -Port 8080
        $process8005 = Get-PortProcess -Port 8005
        
        if ($process8080) {
            Write-Log "Port 8080 in use: $($process8080.ProcessName) (PID: $($process8080.Id))" "WARNING"
        }
        if ($process8005) {
            Write-Log "Port 8005 in use: $($process8005.ProcessName) (PID: $($process8005.Id))" "WARNING"
        }
        
        Write-Host ""
        $confirm = Read-Host "Tomcat may already be running. Continue? (y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Log "Startup cancelled" "WARNING"
            Write-Host ""
            Write-Host "  Tip: To stop Tomcat, run .\stop.ps1" -ForegroundColor Yellow
            exit 0
        }
    }
    else {
        Write-Log "Ports 8080 and 8005 are available" "SUCCESS"
    }
    
    Write-Host ""
    
    # ========== Step 3: Set Environment Variables ==========
    Write-Host "[Step 3] Configure Environment" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $env:JAVA_HOME = $javaHome
    $env:CATALINA_HOME = $catalinaHome
    $env:BOOKGETTER_DATA_DIR = $dataDir
    
    if (-not (Test-Path $dataDir)) {
        Write-Log "Creating data directory: $dataDir" "WARNING"
        New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
    }
    
    Write-Log "Environment configured" "SUCCESS"
    Write-Host ""
    
    # ========== Step 4: Start Tomcat ==========
    Write-Host "[Step 4] Start Tomcat" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $catalinaScript = Join-Path $catalinaHome "bin\catalina.bat"
    
    if ($Background) {
        Write-Log "Starting Tomcat in background..."
        
        Start-Process -FilePath $catalinaScript -ArgumentList "start" -NoNewWindow
        
        if (-not $NoHealthCheck) {
            Write-Host ""
            Wait-ForServiceReady | Out-Null
        }
        
        Write-Host ""
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host "                    Tomcat Started!                            " -ForegroundColor Green
        Write-Host "===============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "   App URL:   $Script:APP_URL" -ForegroundColor White
        Write-Host ""
        Write-Host "   View logs: Get-Content '$catalinaHome\logs\catalina.out' -Wait" -ForegroundColor Yellow
        Write-Host "   Stop:      .\stop.ps1" -ForegroundColor Yellow
        Write-Host ""
    }
    else {
        Write-Log "Starting Tomcat in foreground (Ctrl+C to stop)..."
        Write-Host ""
        Write-Host "   App will be available at: $Script:APP_URL" -ForegroundColor White
        Write-Host ""
        Write-Host "-------------------------------------------" -ForegroundColor DarkGray
        
        & $catalinaScript run
    }
}

try {
    Main
}
catch {
    Write-Log "Error: $_" "ERROR"
    exit 1
}
