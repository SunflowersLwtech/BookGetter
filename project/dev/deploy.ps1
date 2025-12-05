#Requires -Version 5.1
<#
.SYNOPSIS
    BookGetter Deploy Script - Auto-detect environment and deploy application

.DESCRIPTION
    This script automatically detects Java, Tomcat, and Gradle environment.
    Prioritizes reading paths from 项目技术栈信息.md configuration file.
    If an existing deployment is found, it will clean up before redeploying.
    Missing dependencies will show friendly download instructions.

.PARAMETER Help
    Show help information

.PARAMETER Clean
    Only clean deployment, do not redeploy

.PARAMETER SkipBuild
    Skip Gradle build step

.PARAMETER Force
    Force redeploy without confirmation

.EXAMPLE
    .\deploy.ps1
    Normal deployment

.EXAMPLE
    .\deploy.ps1 -Clean
    Only clean existing deployment

.EXAMPLE
    .\deploy.ps1 -SkipBuild
    Deploy using existing WAR file (skip build)
#>

[CmdletBinding()]
param(
    [switch]$Help,
    [switch]$Clean,
    [switch]$SkipBuild,
    [switch]$Force
)

# ==================== Configuration ====================
$Script:VERSION = "1.1.0"
$Script:APP_NAME = "BookGetter"
$Script:WAR_NAME = "BookGetter.war"
$Script:DEPLOY_NAME = "BookGetter"

# Get script directory and project root
$Script:ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Script:ProjectRoot = Split-Path -Parent $Script:ScriptDir
$Script:BookGetterRoot = Split-Path -Parent $Script:ProjectRoot

# Configuration file path
$Script:ConfigFile = Join-Path $Script:BookGetterRoot "项目技术栈信息.md"

# Log file
$Script:LogFile = Join-Path $Script:ProjectRoot "deploy.log"

# ==================== Utility Functions ====================

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        default { Write-Host $logEntry }
    }
    
    Add-Content -Path $Script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
}

function Write-Banner {
    $banner = @"

+==============================================================+
|                   BookGetter Deploy Script                   |
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
    <#
    .SYNOPSIS
        Read paths from 项目技术栈信息.md configuration file
    .DESCRIPTION
        Parses the markdown configuration file to extract Java and Tomcat paths
    #>
    
    $config = @{
        JavaPath        = $null
        TomcatPath      = $null
        ConfigFileFound = $false
    }
    
    if (-not (Test-Path $Script:ConfigFile)) {
        Write-Log "Configuration file not found: $Script:ConfigFile" "WARNING"
        return $config
    }
    
    Write-Log "Reading configuration from: $Script:ConfigFile"
    $config.ConfigFileFound = $true
    
    try {
        $content = Get-Content $Script:ConfigFile -Encoding UTF8 -Raw
        
        # Extract Java path - look for java.exe path in the table or code blocks
        # Pattern: `C:\...\java.exe` or C:\...\java.exe
        if ($content -match '`([^`]*\\java\.exe)`') {
            $javaExePath = $matches[1]
            # Get JAVA_HOME from java.exe path (parent of bin directory or direct parent)
            $javaDir = Split-Path $javaExePath
            if ($javaDir -match '\\bin$') {
                $config.JavaPath = Split-Path $javaDir
            }
            else {
                # java.exe is directly in javapath, try to find actual JDK
                $config.JavaPath = $javaDir
            }
            Write-Log "Config: Java path = $($config.JavaPath)" "SUCCESS"
        }
        
        # Extract Tomcat path - look for apache-tomcat path
        # Pattern: `C:\...\apache-tomcat-...` or in code blocks
        if ($content -match '`([^`]*apache-tomcat-[^`\\]*)`') {
            $config.TomcatPath = $matches[1]
            Write-Log "Config: Tomcat path = $($config.TomcatPath)" "SUCCESS"
        }
        elseif ($content -match '([A-Z]:\\[^\r\n`]*apache-tomcat-[^\r\n`\\]*)') {
            $config.TomcatPath = $matches[1].Trim()
            Write-Log "Config: Tomcat path = $($config.TomcatPath)" "SUCCESS"
        }
    }
    catch {
        Write-Log "Error reading config file: $_" "WARNING"
    }
    
    return $config
}

# ==================== Environment Detection ====================

function Find-JavaHome {
    Write-Log "Detecting Java environment..."
    
    # 1. PRIORITY: Read from configuration file
    $config = Read-ConfigFile
    if ($config.JavaPath) {
        # Try to find actual JAVA_HOME from the configured path
        $javaExe = Join-Path $config.JavaPath "java.exe"
        if (Test-Path $javaExe) {
            # This is javapath directory, find actual JDK
            Write-Log "Found Java in config path, searching for JDK..." "INFO"
        }
        
        # Check common JDK locations based on the config hint
        $jdkPaths = @(
            "C:\Program Files\Java\jdk-*",
            "C:\Program Files\Eclipse Adoptium\jdk-*",
            "C:\Program Files\Microsoft\jdk-*",
            "C:\Program Files\Amazon Corretto\jdk*",
            "C:\Program Files\OpenJDK\jdk-*"
        )
        
        foreach ($pattern in $jdkPaths) {
            $found = Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | 
            Where-Object { $_.PSIsContainer } |
            Sort-Object Name -Descending | 
            Select-Object -First 1
            if ($found -and (Test-Path "$($found.FullName)\bin\java.exe")) {
                Write-Log "Found JDK at: $($found.FullName)" "SUCCESS"
                return $found.FullName
            }
        }
    }
    
    # 2. Check environment variable
    if ($env:JAVA_HOME -and (Test-Path "$env:JAVA_HOME\bin\java.exe")) {
        Write-Log "Found JAVA_HOME from env: $env:JAVA_HOME" "SUCCESS"
        return $env:JAVA_HOME
    }
    
    # 3. Check common paths
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
            Write-Log "Found Java at: $($found.FullName)" "SUCCESS"
            return $found.FullName
        }
    }
    
    # 4. Check registry
    try {
        $regPaths = @(
            "HKLM:\SOFTWARE\JavaSoft\Java Development Kit",
            "HKLM:\SOFTWARE\JavaSoft\JDK"
        )
        foreach ($regPath in $regPaths) {
            if (Test-Path $regPath) {
                $version = (Get-ItemProperty $regPath -ErrorAction SilentlyContinue).CurrentVersion
                if ($version) {
                    $javaHome = (Get-ItemProperty "$regPath\$version" -ErrorAction SilentlyContinue).JavaHome
                    if ($javaHome -and (Test-Path "$javaHome\bin\java.exe")) {
                        Write-Log "Found Java from registry: $javaHome" "SUCCESS"
                        return $javaHome
                    }
                }
            }
        }
    }
    catch { }
    
    # 5. Check PATH
    $javaInPath = Get-Command java.exe -ErrorAction SilentlyContinue
    if ($javaInPath) {
        $javaExe = $javaInPath.Source
        $javaHome = Split-Path (Split-Path $javaExe)
        Write-Log "Found Java in PATH: $javaHome" "SUCCESS"
        return $javaHome
    }
    
    return $null
}

function Find-CatalinaHome {
    Write-Log "Detecting Tomcat environment..."
    
    # 1. PRIORITY: Read from configuration file
    $config = Read-ConfigFile
    if ($config.TomcatPath -and (Test-Path "$($config.TomcatPath)\bin\catalina.bat")) {
        Write-Log "Found Tomcat from config: $($config.TomcatPath)" "SUCCESS"
        return $config.TomcatPath
    }
    
    # 2. Check environment variable
    if ($env:CATALINA_HOME -and (Test-Path "$env:CATALINA_HOME\bin\catalina.bat")) {
        Write-Log "Found CATALINA_HOME from env: $env:CATALINA_HOME" "SUCCESS"
        return $env:CATALINA_HOME
    }
    
    # 3. Check common paths (including the config-referenced path)
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
            Write-Log "Found Tomcat at: $($found.FullName)" "SUCCESS"
            return $found.FullName
        }
    }
    
    return $null
}

function Test-GradleWrapper {
    Write-Log "Checking Gradle Wrapper..."
    
    $gradlewPath = Join-Path $Script:ProjectRoot "gradlew.bat"
    $wrapperJar = Join-Path $Script:ProjectRoot "gradle\wrapper\gradle-wrapper.jar"
    
    if ((Test-Path $gradlewPath) -and (Test-Path $wrapperJar)) {
        Write-Log "Gradle Wrapper is available" "SUCCESS"
        return $true
    }
    
    Write-Log "Gradle Wrapper is incomplete" "WARNING"
    return $false
}

function Show-DependencyHelp {
    param([string]$Missing)
    
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host "                    Missing Required Dependency                " -ForegroundColor Red
    Write-Host "===============================================================" -ForegroundColor Red
    Write-Host ""
    
    switch ($Missing) {
        "Java" {
            Write-Host "[X] Java JDK 17+ not detected" -ForegroundColor Red
            Write-Host ""
            Write-Host "[Download Links]" -ForegroundColor Yellow
            Write-Host "   Eclipse Temurin (Recommended): https://adoptium.net/temurin/releases/" -ForegroundColor White
            Write-Host "   Oracle JDK:                    https://www.oracle.com/java/technologies/downloads/" -ForegroundColor White
            Write-Host ""
            Write-Host "[Installation Steps]" -ForegroundColor Yellow
            Write-Host "   1. Download JDK 17+ Windows x64 installer (.msi)" -ForegroundColor White
            Write-Host "   2. Run the installer" -ForegroundColor White
            Write-Host "   3. Check 'Set JAVA_HOME variable' during installation" -ForegroundColor White
            Write-Host "   4. Reopen PowerShell window" -ForegroundColor White
            Write-Host "   5. Verify: java -version" -ForegroundColor White
        }
        "Tomcat" {
            Write-Host "[X] Apache Tomcat 11+ not detected" -ForegroundColor Red
            Write-Host ""
            Write-Host "[Download Link]" -ForegroundColor Yellow
            Write-Host "   https://tomcat.apache.org/download-11.cgi" -ForegroundColor White
            Write-Host ""
            Write-Host "[Installation Steps]" -ForegroundColor Yellow
            Write-Host "   1. Download '64-bit Windows zip' under 'Core'" -ForegroundColor White
            Write-Host "   2. Extract to any directory (e.g. C:\apache-tomcat-11.x.x)" -ForegroundColor White
            Write-Host "   3. Set CATALINA_HOME environment variable:" -ForegroundColor White
            Write-Host '      $env:CATALINA_HOME = "C:\apache-tomcat-11.x.x"' -ForegroundColor Cyan
            Write-Host "   4. Or set permanently via System Properties > Environment Variables" -ForegroundColor White
            Write-Host ""
            Write-Host "[Config File]" -ForegroundColor Yellow
            Write-Host "   You can also add the path to: $Script:ConfigFile" -ForegroundColor White
        }
        "Gradle" {
            Write-Host "[X] Gradle Wrapper files missing" -ForegroundColor Red
            Write-Host ""
            Write-Host "[Fix Steps]" -ForegroundColor Yellow
            Write-Host "   1. Ensure these files exist:" -ForegroundColor White
            Write-Host "      - gradlew.bat" -ForegroundColor Cyan
            Write-Host "      - gradle/wrapper/gradle-wrapper.jar" -ForegroundColor Cyan
            Write-Host "      - gradle/wrapper/gradle-wrapper.properties" -ForegroundColor Cyan
            Write-Host "   2. If missing, re-pull from Git repository" -ForegroundColor White
            Write-Host "   3. Or install Gradle manually: https://gradle.org/install/" -ForegroundColor White
        }
    }
    Write-Host ""
}

# ==================== Deployment Detection ====================

function Test-ExistingDeployment {
    param([string]$CatalinaHome)
    
    $warFile = Join-Path $CatalinaHome "webapps\$Script:DEPLOY_NAME.war"
    $explodedDir = Join-Path $CatalinaHome "webapps\$Script:DEPLOY_NAME"
    
    $exists = (Test-Path $warFile) -or (Test-Path $explodedDir)
    
    if ($exists) {
        Write-Log "Existing deployment detected" "WARNING"
        return $true
    }
    return $false
}

function Clear-Deployment {
    param([string]$CatalinaHome)
    
    Write-Log "Cleaning old deployment..."
    
    $warFile = Join-Path $CatalinaHome "webapps\$Script:DEPLOY_NAME.war"
    $explodedDir = Join-Path $CatalinaHome "webapps\$Script:DEPLOY_NAME"
    
    if (Test-Path $warFile) {
        Remove-Item -Path $warFile -Force
        Write-Log "Removed: $warFile" "SUCCESS"
    }
    
    if (Test-Path $explodedDir) {
        Remove-Item -Path $explodedDir -Recurse -Force
        Write-Log "Removed: $explodedDir" "SUCCESS"
    }
}

function Test-TomcatRunning {
    $port8080 = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue
    $port8005 = Get-NetTCPConnection -LocalPort 8005 -ErrorAction SilentlyContinue
    return ($port8080 -or $port8005)
}

function Stop-TomcatIfRunning {
    param([string]$CatalinaHome)
    
    if (Test-TomcatRunning) {
        Write-Log "Tomcat is running, stopping..." "WARNING"
        
        $stopScript = Join-Path $Script:ScriptDir "stop.ps1"
        if (Test-Path $stopScript) {
            & $stopScript
        }
        else {
            try {
                & "$CatalinaHome\bin\catalina.bat" stop
                Start-Sleep -Seconds 5
            }
            catch {
                Write-Log "Graceful stop failed, forcing..." "WARNING"
                Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
            }
        }
        
        Start-Sleep -Seconds 2
        if (Test-TomcatRunning) {
            Write-Log "Tomcat still running, forcing stop..." "WARNING"
            Stop-Process -Name "java" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        Write-Log "Tomcat stopped" "SUCCESS"
    }
}

# ==================== Build Functions ====================

function Invoke-ProjectBuild {
    param([string]$JavaHome)
    
    Write-Log "Building project..."
    
    $env:JAVA_HOME = $JavaHome
    
    Push-Location $Script:ProjectRoot
    
    try {
        $gradlew = Join-Path $Script:ProjectRoot "gradlew.bat"
        
        Write-Log "Executing: gradlew war"
        & $gradlew war | Out-Host
        
        if ($LASTEXITCODE -ne 0) {
            throw "Gradle build failed with exit code: $LASTEXITCODE"
        }
        
        $Script:BuiltWarPath = Join-Path $Script:ProjectRoot "build\libs\$Script:WAR_NAME"
        if (-not (Test-Path $Script:BuiltWarPath)) {
            throw "WAR file not generated: $Script:BuiltWarPath"
        }
        
        $warSize = (Get-Item $Script:BuiltWarPath).Length / 1MB
        Write-Log "Build successful! WAR size: $([math]::Round($warSize, 2)) MB" "SUCCESS"
    }
    finally {
        Pop-Location
    }
}

# ==================== Deploy Functions ====================

function Copy-WarToTomcat {
    param(
        [string]$WarSource,
        [string]$CatalinaHome
    )
    
    Write-Log "Deploying WAR file..."
    
    $warDest = Join-Path $CatalinaHome "webapps\$Script:DEPLOY_NAME.war"
    
    Copy-Item -Path $WarSource -Destination $warDest -Force
    
    if (Test-Path $warDest) {
        Write-Log "WAR deployed to: $warDest" "SUCCESS"
        return $true
    }
    else {
        throw "WAR file copy failed"
    }
}

# ==================== Main ====================

function Main {
    if ($Help) {
        Show-Help
        return
    }
    
    Write-Banner
    
    $startTime = Get-Date
    Write-Log "Starting deployment process..."
    Write-Log "Project directory: $Script:ProjectRoot"
    Write-Log "Config file: $Script:ConfigFile"
    
    # ========== Step 1: Environment Detection ==========
    Write-Host ""
    Write-Host "[Step 1] Environment Detection" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $javaHome = Find-JavaHome
    if (-not $javaHome) {
        Show-DependencyHelp -Missing "Java"
        exit 1
    }
    
    $javaExe = Join-Path $javaHome "bin\java.exe"
    $javaVersion = & $javaExe -version 2>&1 | Select-String -Pattern 'version "(\d+)' | ForEach-Object { $_.Matches.Groups[1].Value }
    Write-Log "Java version: $javaVersion"
    if ([int]$javaVersion -lt 17) {
        Write-Log "Java 17+ required, current: $javaVersion" "ERROR"
        Show-DependencyHelp -Missing "Java"
        exit 1
    }
    
    $catalinaHome = Find-CatalinaHome
    if (-not $catalinaHome) {
        Show-DependencyHelp -Missing "Tomcat"
        exit 1
    }
    
    $tomcatVersion = (Get-Content "$catalinaHome\RELEASE-NOTES" -ErrorAction SilentlyContinue | Select-String "Apache Tomcat Version" | ForEach-Object { $_ -replace '.*Version\s*', '' }).Trim()
    if ($tomcatVersion) {
        Write-Log "Tomcat version: $tomcatVersion"
    }
    
    if (-not (Test-GradleWrapper)) {
        Show-DependencyHelp -Missing "Gradle"
        exit 1
    }
    
    Write-Host ""
    Write-Host "[OK] Environment check passed" -ForegroundColor Green
    Write-Host ""
    
    # ========== Step 2: Clean Old Deployment ==========
    Write-Host "[Step 2] Check Existing Deployment" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    Stop-TomcatIfRunning -CatalinaHome $catalinaHome
    
    if (Test-ExistingDeployment -CatalinaHome $catalinaHome) {
        if (-not $Force) {
            Write-Host ""
            $confirm = Read-Host "Existing deployment found. Clean and redeploy? (Y/n)"
            if ($confirm -eq 'n' -or $confirm -eq 'N') {
                Write-Log "User cancelled deployment" "WARNING"
                exit 0
            }
        }
        Clear-Deployment -CatalinaHome $catalinaHome
    }
    else {
        Write-Log "No existing deployment found, will do fresh deploy"
    }
    
    if ($Clean) {
        Write-Log "Cleanup complete!" "SUCCESS"
        return
    }
    
    Write-Host ""
    
    # ========== Step 3: Build Project ==========
    Write-Host "[Step 3] Build Project" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    if ($SkipBuild) {
        Write-Log "Skipping build step (-SkipBuild)" "WARNING"
        $warPath = Join-Path $Script:ProjectRoot "build\libs\$Script:WAR_NAME"
        if (-not (Test-Path $warPath)) {
            Write-Log "WAR file not found: $warPath" "ERROR"
            exit 1
        }
    }
    else {
        try {
            Invoke-ProjectBuild -JavaHome $javaHome
            $warPath = $Script:BuiltWarPath
        }
        catch {
            Write-Log "Build failed: $_" "ERROR"
            exit 1
        }
    }
    
    Write-Host ""
    
    # ========== Step 4: Deploy WAR ==========
    Write-Host "[Step 4] Deploy Application" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    try {
        Copy-WarToTomcat -WarSource $warPath -CatalinaHome $catalinaHome
    }
    catch {
        Write-Log "Deployment failed: $_" "ERROR"
        exit 1
    }
    
    Write-Host ""
    
    # ========== Step 5: Start Server ==========
    Write-Host "[Step 5] Start Server" -ForegroundColor Cyan
    Write-Host "-------------------------------------------" -ForegroundColor DarkGray
    
    $startScript = Join-Path $Script:ScriptDir "start.ps1"
    if (Test-Path $startScript) {
        Write-Log "Calling start script..."
        & $startScript
    }
    else {
        Write-Log "Start script not found, please start Tomcat manually" "WARNING"
    }
    
    # ========== Done ==========
    $endTime = Get-Date
    $duration = $endTime - $startTime
    
    Write-Host ""
    Write-Host "===============================================================" -ForegroundColor Green
    Write-Host "                    Deployment Complete!                       " -ForegroundColor Green
    Write-Host "===============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "   App URL:   http://localhost:8080/BookGetter/" -ForegroundColor White
    Write-Host "   Duration:  $([math]::Round($duration.TotalSeconds, 1)) seconds" -ForegroundColor White
    Write-Host ""
}

# Run main
try {
    Main
}
catch {
    Write-Log "Unexpected error: $_" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    exit 1
}
