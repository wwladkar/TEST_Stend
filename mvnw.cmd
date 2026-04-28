@REM Maven Wrapper launch script for Windows
@REM This script downloads Maven if not available and runs the build

@echo off
setlocal enabledelayedexpansion

set "MAVEN_PROJECTBASEDIR=%~dp0"
set "MAVEN_PROJECTBASEDIR=%MAVEN_PROJECTBASEDIR:~0,-1%"
set "MAVEN_CMD_LINE_ARGS=%*"

set "WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar"

if exist "%WRAPPER_JAR%" goto runWrapper

echo Downloading Maven Wrapper...
set "DOWNLOAD_URL=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar"

powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%WRAPPER_JAR%' }" 2>nul
if not exist "%WRAPPER_JAR%" (
    echo Failed to download Maven Wrapper
    echo Please download manually from:
    echo   %DOWNLOAD_URL%
    echo and place it at: %WRAPPER_JAR%
    exit /b 1
)

:runWrapper
if not defined JAVA_HOME (
    echo JAVA_HOME is not set. Please set JAVA_HOME to point to a JDK 17+ installation.
    exit /b 1
)

"%JAVA_HOME%\bin\java.exe" -Dmaven.multiModuleProjectDirectory="%MAVEN_PROJECTBASEDIR%" -classpath "%WRAPPER_JAR%" org.apache.maven.wrapper.MavenWrapperMain %MAVEN_CMD_LINE_ARGS%
