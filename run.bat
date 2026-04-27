@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: ============================================================
::  TEST Stend — единый скрипт управления
::  Использование:
::    run.bat          — собрать и запустить
::    run.bat start    — запустить без сборки
::    run.bat stop     — остановить все сервисы
::    run.bat status   — проверить состояние
::    run.bat clean    — очистить БД и пересобрать
:: ============================================================

:: --- Конфигурация ---
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot"
set "MVN_HOME=C:\Program Files\JetBrains\IntelliJ IDEA Community Edition 2024.3.2.2\plugins\maven\lib\maven3"
set "JAVA=%JAVA_HOME%\bin\java.exe"
set "MVN=%MVN_HOME%\bin\mvn.cmd"
set "FRONTEND_DIR=frontend"
set "AUTH_JAR=auth-service\target\auth-service-1.0.0-SNAPSHOT.jar"
set "CORE_JAR=core-service\target\core-service-1.0.0-SNAPSHOT.jar"
set "GATEWAY_JAR=api-gateway\target\api-gateway-1.0.0-SNAPSHOT.jar"

:: --- Загрузка .env ---
if not exist ".env" (
    echo [ERROR] Файл .env не найден. Создайте его из .env.example
    exit /b 1
)
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    if not "%%a"=="" if not "%%a:~0,1%"=="#" (
        set "%%a=%%b"
    )
)

:: --- Маршрутизация по аргументу ---
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=build-and-start"
if "%ACTION%"=="start" goto :start
if "%ACTION%"=="stop" goto :stop
if "%ACTION%"=="status" goto :status
if "%ACTION%"=="clean" goto :clean
if "%ACTION%"=="build-and-start" goto :build
echo [ERROR] Неизвестная команда: %ACTION%
echo Доступные: run.bat [start^|stop^|status^|clean]
exit /b 1

:: ===================== BUILD =====================
:build
echo.
echo [1/4] Сборка проекта...
if not exist "%MVN%" (
    echo [ERROR] Maven не найден: %MVN%
    exit /b 1
)
call "%MVN%" clean package -DskipTests -q
if errorlevel 1 (
    echo [ERROR] Сборка не удалась
    exit /b 1
)
echo       Сборка завершена успешно

:: ===================== START =====================
:start
:: Проверка JAR
for %%j in ("%AUTH_JAR%" "%CORE_JAR%" "%GATEWAY_JAR%") do (
    if not exist "%%j" (
        echo [ERROR] Не найден: %%j
        echo         Запустите: run.bat (без аргументов) для сборки
        exit /b 1
    )
)

:: Проверка: не запущены ли уже
netstat -ano 2>nul | findstr ":8081 " | findstr "LISTEN" >nul && (
    echo [WARN] Auth Service уже запущен на :8081
    goto :check_ports
)

echo.
echo [2/4] Запуск Auth Service (:8081)...
start "Auth Service" /min "%JAVA%" -jar "%AUTH_JAR%"

timeout /t 4 /nobreak >nul

echo       Запуск Core Service (:8082)...
start "Core Service" /min "%JAVA%" -jar "%CORE_JAR%"

timeout /t 4 /nobreak >nul

echo       Запуск API Gateway (:8080)...
start "API Gateway" /min "%JAVA%" -jar "%GATEWAY_JAR%"

echo.
echo [3/4] Запуск Frontend (:3000)...
cd "%FRONTEND_DIR%"
start "Frontend" /min cmd /c "npm run dev"
cd ..

echo       Ожидание запуска сервисов...
timeout /t 18 /nobreak >nul

:: ===================== STATUS (health check) =====================
:check_ports
:status
echo.
echo [4/4] Проверка состояния:
echo ┌───────────────────┬────────┬─────────┐
echo │ Сервис            │  Порт  │ Статус  │
echo ├───────────────────┼────────┼─────────┤

set "ALL_UP=1"

for %%p in ("8081 Auth Service" "8082 Core Service" "8080 API Gateway" "3000 Frontend") do (
    for /f "tokens=1,*" %%a in (%%p) do (
        set "PORT=%%a"
        set "NAME=%%b"
        netstat -ano 2>nul | findstr ":!PORT! " | findstr "LISTEN" >nul 2>&1
        if !errorlevel! equ 0 (
            echo │ !NAME:~-18! │  :!PORT! │   UP    │
        ) else (
            echo │ !NAME:~-18! │  :!PORT! │  DOWN   │
            set "ALL_UP=0"
        )
    )
)
echo └───────────────────┴────────┴─────────┘

if "%ALL_UP%"=="1" (
    echo.
    echo ✅ Стенд запущен: http://localhost:3000
) else (
    echo.
    echo ⚠  Не все сервисы поднялись. Проверьте логи.
)
goto :eof

:: ===================== STOP =====================
:stop
echo.
echo Остановка сервисов...

:: Убиваем java.exe, запущенные из нашего проекта
for /f "tokens=2" %%i in ('wmic process where "Name='java.exe'" get ProcessId /format:list 2^>nul ^| findstr "ProcessId"') do (
    wmic process where "ProcessId=%%i" get CommandLine /format:list 2>nul | findstr /i "test-stend\|auth-service\|core-service\|api-gateway" >nul 2>&1
    if !errorlevel! equ 0 (
        taskkill /pid %%i /f >nul 2>&1
        echo       Остановлен java PID=%%i
    )
)

:: Убиваем node (frontend dev server)
for /f "tokens=2" %%i in ('wmic process where "Name='node.exe'" get ProcessId /format:list 2^>nul ^| findstr "ProcessId"') do (
    wmic process where "ParentProcessId=%%i or ProcessId=%%i" get CommandLine /format:list 2>nul | findstr /i "vite" >nul 2>&1
    if !errorlevel! equ 0 (
        taskkill /pid %%i /f >nul 2>&1
        echo       Остановлен node PID=%%i
    )
)

echo       Все сервисы остановлены
goto :eof

:: ===================== CLEAN =====================
:clean
echo.
echo [1/3] Остановка сервисов...
call :stop

echo.
echo [2/3] Очистка БД...
if exist "data\auth-db.mv.db" del /q "data\auth-db.mv.db" && echo       Удалена auth-db.mv.db
if exist "data\auth-db.trace.db" del /q "data\auth-db.trace.db" 2>nul
if exist "data\core-db.mv.db" del /q "data\core-db.mv.db" && echo       Удалена core-db.mv.db
if exist "data\core-db.trace.db" del /q "data\core-db.trace.db" 2>nul

echo.
echo [3/3] Пересборка...
call "%MVN%" clean package -DskipTests -q
if errorlevel 1 (
    echo [ERROR] Сборка не удалась
    exit /b 1
)
echo       Сборка завершена. Запустите: run.bat start
goto :eof