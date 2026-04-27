# ============================================================
#  TEST Stend — unified management script
#  Usage:
#    .\stend.ps1           — build + start
#    .\stend.ps1 start     — start without build
#    .\stend.ps1 stop      — stop all services
#    .\stend.ps1 status    — check status
#    .\stend.ps1 clean     — stop + delete DB + rebuild
#    .\stend.ps1 restart   — stop + start
# ============================================================

$ErrorActionPreference = "Stop"

# --- Configuration ---
$Script:JavaHome = "C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
$Script:JavaExe = Join-Path $JavaHome "bin\java.exe"
$Script:MavenHome = "C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2024.3.2.2\plugins\maven\lib\maven3"
$Script:MvnCmd = Join-Path $MavenHome "bin\mvn.cmd"
$Script:WorkDir = "C:\Users\User\IdeaProjects\TEST_Stend"
$Script:FrontendDir = Join-Path $WorkDir "frontend"
$Script:SpringProfile = "dev"
$Script:LogDir = Join-Path $WorkDir "logs"

$Script:Services = @(
    @{ Name = "Auth Service";  Port = 8081; Jar = "auth-service\target\auth-service-1.0.0-SNAPSHOT.jar" }
    @{ Name = "Core Service";  Port = 8082; Jar = "core-service\target\core-service-1.0.0-SNAPSHOT.jar" }
    @{ Name = "API Gateway";   Port = 8080; Jar = "api-gateway\target\api-gateway-1.0.0-SNAPSHOT.jar" }
)
$Script:Frontend = @{ Name = "Frontend"; Port = 3000 }

# --- Load .env ---
function Load-Env {
    $envFile = Join-Path $WorkDir ".env"
    if (-not (Test-Path $envFile)) {
        Write-Host "[ERROR] .env not found. Copy from .env.example" -ForegroundColor Red
        exit 1
    }
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), "Process")
        }
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

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $JavaExe
    $psi.Arguments = "-Dspring.profiles.active=$SpringProfile -jar `"$jarPath`""
    $psi.WorkingDirectory = $WorkDir
    $psi.UseShellExecute = $false
    # No output redirection — prevents blocking
    $psi.CreateNoWindow = $true

    # Inherit all current env vars (includes JWT_SECRET from .env)
    foreach ($key in [Environment]::GetEnvironmentVariables("Process").Keys) {
        $psi.EnvironmentVariables[$key] = [Environment]::GetEnvironmentVariable($key, "Process")
    }

    [System.Diagnostics.Process]::Start($psi) | Out-Null
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
    # Check via netstat — works for both IPv4 and IPv6
    $result = netstat -ano 2>$null | Select-String ":$Port " | Select-String "LISTEN"
    return ($null -ne $result)
}

# ========================= BUILD =========================
function Invoke-Build {
    Write-Host ""
    Write-Host "[BUILD] Assembling project..." -ForegroundColor Cyan
    if (-not (Test-Path $MvnCmd)) {
        Write-Host "  [ERROR] Maven not found: $MvnCmd" -ForegroundColor Red
        exit 1
    }
    $env:JAVA_HOME = $JavaHome
    & $MvnCmd clean package -DskipTests -q 2>&1 | Out-Null
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
            Write-Host " FAILED" -ForegroundColor Red
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
    Write-Host "[CLEAN] Removing H2 data..." -ForegroundColor Cyan
    $dataDir = Join-Path $WorkDir "data"
    if (Test-Path $dataDir) {
        Remove-Item $dataDir -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  H2 data removed" -ForegroundColor Green
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
    default   { Write-Host "Unknown command: $action`nUsage: .\stend.ps1 [start|stop|restart|status|clean]" -ForegroundColor Red; exit 1 }
}
