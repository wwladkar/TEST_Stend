# ============================================================
#  TEST Stend — unified management script (Windows)
#  Usage:
#    .\stend.ps1           — build + start
#    .\stend.ps1 start     — start without build
#    .\stend.ps1 stop      — stop all services
#    .\stend.ps1 status    — check status
#    .\stend.ps1 clean     — stop + delete DB + rebuild
#    .\stend.ps1 restart   — stop + start
# ============================================================

$ErrorActionPreference = "Stop"

# --- Configuration (auto-detected) ---
$Script:WorkDir     = $PSScriptRoot
$Script:FrontendDir = Join-Path $WorkDir "frontend"
$Script:LogDir      = Join-Path $WorkDir "logs"
$Script:SpringProfile = ""   # empty = H2 default; set to "pg" for PostgreSQL

# Auto-detect Java
$Script:JavaHome = if ($env:JAVA_HOME) { $env:JAVA_HOME } else {
    $javaCmd = Get-Command java -ErrorAction SilentlyContinue
    if ($javaCmd) { Split-Path (Split-Path $javaCmd.Source) } else { $null }
}
$Script:JavaExe = if ($JavaHome) { Join-Path $JavaHome "bin\java.exe" } else { $null }

# Auto-detect Maven: Maven Wrapper > IDEA bundled > system
$Script:MvnCmd = $null
$mavenWrapper = Join-Path $WorkDir "mvnw.cmd"
if (Test-Path $mavenWrapper) {
    $Script:MvnCmd = $mavenWrapper
} elseif ($env:MAVEN_HOME) {
    $Script:MvnCmd = Join-Path $env:MAVEN_HOME "bin\mvn.cmd"
} else {
    $sysMvn = Get-Command mvn.cmd -ErrorAction SilentlyContinue
    if ($sysMvn) { $Script:MvnCmd = $sysMvn.Source }
}

$Script:Services = @(
    @{ Name = "Auth Service";  Port = 8081; Jar = "auth-service\target\auth-service-1.0.0-SNAPSHOT.jar" }
    @{ Name = "Core Service";  Port = 8082; Jar = "core-service\target\core-service-1.0.0-SNAPSHOT.jar" }
    @{ Name = "API Gateway";   Port = 8080; Jar = "api-gateway\target\api-gateway-1.0.0-SNAPSHOT.jar" }
)
$Script:Frontend = @{ Name = "Frontend"; Port = 3000 }

# --- Load and validate .env ---
function Load-Env {
    $envFile = Join-Path $WorkDir ".env"
    if (-not (Test-Path $envFile)) {
        Write-Host "[ERROR] .env not found. Run: copy .env.example .env" -ForegroundColor Red
        exit 1
    }
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
    }

    # Validate JWT_SECRET
    $placeholder = "your-random-secret-at-least-32-bytes-long!!"
    if (-not $env:JWT_SECRET -or $env:JWT_SECRET -eq $placeholder) {
        Write-Host "[ERROR] JWT_SECRET is not set or has placeholder value. Edit .env!" -ForegroundColor Red
        exit 1
    }
}

# --- Start a Java service via ProcessStartInfo ---
function Start-JavaService {
    param([hashtable]$Svc)
    $jarPath = Join-Path $WorkDir $Svc.Jar
    if (-not (Test-Path $jarPath)) {
        Write-Host "  [ERROR] JAR not found: $($Svc.Jar)" -ForegroundColor Red
        return $false
    }

    $profileArg = if ($SpringProfile) { "-Dspring.profiles.active=$SpringProfile" } else { "" }
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $JavaExe
    $psi.Arguments = "$profileArg -jar `"$jarPath`""
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    # Redirect stdout/stderr to log files
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $stdLog = Join-Path $LogDir "$($Svc.Name -replace ' ','').log"
    $errLog = Join-Path $LogDir "$($Svc.Name -replace ' ','')-error.log"

    # Inherit all current env vars (includes JWT_SECRET from .env)
    foreach ($key in [Environment]::GetEnvironmentVariables("Process").Keys) {
        $psi.EnvironmentVariables[$key] = [Environment]::GetEnvironmentVariable($key, "Process")
    }

    $proc = [System.Diagnostics.Process]::Start($psi)

    # Async redirect to log files
    $stdSw  = [System.IO.StreamWriter]::new($stdLog, $true)
    $errSw  = [System.IO.StreamWriter]::new($errLog, $true)
    $proc.BeginOutputReadLine()
    $proc.BeginErrorReadLine()
    Register-ObjectEvent -InputObject $proc -EventName OutputDataReceived -Action {
        if ($Event.SourceEventArgs.Data) { $stdSw.WriteLine($Event.SourceEventArgs.Data) }
    } | Out-Null
    Register-ObjectEvent -InputObject $proc -EventName ErrorDataReceived -Action {
        if ($Event.SourceEventArgs.Data) { $errSw.WriteLine($Event.SourceEventArgs.Data) }
    } | Out-Null

    return $true
}

# --- Wait for a TCP port to become available (with retry) ---
function Wait-ForPort {
    param([int]$Port, [int]$TimeoutSec = 30)
    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        if (Test-Port $Port) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

# --- Check if a TCP port is open ---
function Test-Port {
    param([int]$Port)
    $result = netstat -ano 2>$null | Select-String ":$Port " | Select-String "LISTEN"
    return ($null -ne $result)
}

# ========================= BUILD =========================
function Invoke-Build {
    Write-Host ""
    Write-Host "[BUILD] Assembling project..." -ForegroundColor Cyan

    if (-not $JavaExe -or -not (Test-Path $JavaExe)) {
        Write-Host "  [ERROR] Java not found. Set JAVA_HOME or add java to PATH." -ForegroundColor Red
        exit 1
    }
    if (-not $MvnCmd -or -not (Test-Path $MvnCmd)) {
        Write-Host "  [ERROR] Maven not found. Install Maven or use Maven Wrapper (mvnw.cmd)." -ForegroundColor Red
        exit 1
    }

    $env:JAVA_HOME = $JavaHome
    Write-Host "  Java:   $JavaExe" -ForegroundColor Gray
    Write-Host "  Maven:  $MvnCmd" -ForegroundColor Gray

    if ($MvnCmd.EndsWith('.cmd')) {
        $buildOutput = cmd /c "`"$MvnCmd`" clean package -DskipTests -q" 2>&1
        $buildOutput | Out-Null
    } else {
        & $MvnCmd clean package -DskipTests -q 2>&1 | Out-Null
    }
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  [ERROR] Build failed" -ForegroundColor Red
        exit 1
    }
    Write-Host "  Build OK" -ForegroundColor Green
}

# ========================= START =========================
function Invoke-Start {
    foreach ($svc in $Services) {
        $jarPath = Join-Path $WorkDir $svc.Jar
        if (-not (Test-Path $jarPath)) {
            Write-Host "[ERROR] JAR not found: $($svc.Jar). Run .\stend.ps1 to build." -ForegroundColor Red
            exit 1
        }
    }

    Load-Env

    # Ensure log dir exists
    if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

    Write-Host ""
    Write-Host "[START] Launching services..." -ForegroundColor Cyan

    foreach ($svc in $Services) {
        if (Test-Port $svc.Port) {
            Write-Host "  $($svc.Name) (:$($svc.Port)) already running" -ForegroundColor Yellow
            continue
        }
        Write-Host "  $($svc.Name) (:$($svc.Port))..." -NoNewline
        Start-JavaService $svc | Out-Null
        if (Wait-ForPort -Port $svc.Port -TimeoutSec 30) {
            Write-Host " OK" -ForegroundColor Green
        } else {
            Write-Host " FAILED (check logs/)" -ForegroundColor Red
        }
    }

    if (Test-Port $Frontend.Port) {
        Write-Host "  Frontend (:3000) already running" -ForegroundColor Yellow
    } else {
        Write-Host "  Frontend (:3000)..." -NoNewline
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c", "cd /d `"$FrontendDir`" && npm run dev" -WindowStyle Minimized
        if (Wait-ForPort -Port $Frontend.Port -TimeoutSec 15) {
            Write-Host " OK" -ForegroundColor Green
        } else {
            Write-Host " FAILED" -ForegroundColor Red
        }
    }

    Show-Status
}

# ========================= STOP =========================
function Invoke-Stop {
    Write-Host ""
    Write-Host "[STOP] Stopping all services..." -ForegroundColor Cyan
    $stopped = 0
    Get-WmiObject Win32_Process -Filter "Name='java.exe'" | ForEach-Object {
        if ($_.CommandLine -match "auth-service|core-service|api-gateway") {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            $stopped++
        }
    }
    Get-WmiObject Win32_Process -Filter "Name='node.exe'" | ForEach-Object {
        if ($_.CommandLine -match "vite") {
            Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
            $stopped++
        }
    }
    if ($stopped -eq 0) {
        Write-Host "  No services running" -ForegroundColor Yellow
    } else {
        Write-Host "  Stopped $stopped process(es)" -ForegroundColor Green
    }
}

# ========================= STATUS =========================
function Show-Status {
    Write-Host ""
    Write-Host "[STATUS]" -ForegroundColor Cyan
    $allUp = $true
    foreach ($svc in $Services) {
        $up = Test-Port $svc.Port
        $status = if ($up) { "  UP  " } else { " DOWN " }
        $color = if ($up) { "Green" } else { "Red" }
        Write-Host "  $($svc.Name.PadRight(14)) :$($svc.Port)  $status" -ForegroundColor $color
        if (-not $up) { $allUp = $false }
    }
    $fUp = Test-Port $Frontend.Port
    $fStatus = if ($fUp) { "  UP  " } else { " DOWN " }
    $fColor = if ($fUp) { "Green" } else { "Red" }
    Write-Host "  $($Frontend.Name.PadRight(14)) :$($Frontend.Port)  $fStatus" -ForegroundColor $fColor
    if (-not $fUp) { $allUp = $false }

    Write-Host ""
    if ($allUp) {
        Write-Host "  All services running: http://localhost:3000" -ForegroundColor Green
    } else {
        Write-Host "  Some services are down." -ForegroundColor Yellow
    }
}

# ========================= CLEAN =========================
function Invoke-Clean {
    Invoke-Stop
    Write-Host ""
    Write-Host "[CLEAN] Removing H2 data and logs..." -ForegroundColor Cyan
    $dataDir = Join-Path $WorkDir "data"
    if (Test-Path $dataDir) {
        Remove-Item $dataDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  H2 data removed" -ForegroundColor Green
    }
    if (Test-Path $LogDir) {
        Remove-Item $LogDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  Logs removed" -ForegroundColor Green
    }
    Write-Host "  Rebuilding..." -ForegroundColor Cyan
    Invoke-Build
    Write-Host "  Done. Run: .\stend.ps1 start" -ForegroundColor Green
}

# ========================= MAIN =========================
$action = if ($args.Count -gt 0) { $args[0].ToLower() } else { "build" }

switch ($action) {
    "build"   { Invoke-Build; Invoke-Start }
    "start"   { Invoke-Start }
    "stop"    { Invoke-Stop }
    "restart" { Invoke-Stop; Start-Sleep 3; Invoke-Start }
    "status"  { Show-Status }
    "clean"   { Invoke-Clean }
    default   { Write-Host "Unknown command: $action`nUsage: .\stend.ps1 [build|start|stop|restart|status|clean]" -ForegroundColor Red; exit 1 }
}
