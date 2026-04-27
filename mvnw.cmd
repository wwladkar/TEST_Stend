@REM Maven Wrapper launch script for Windows
@REM This script downloads Maven if not available and runs the build

@echo off
setlocal

set "MAVEN_PROJECTBASEDIR=%~dp0.."
set "MAVEN_CMD_LINE_ARGS=%*"

if exist "%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar" goto runWrapper

echo Downloading Maven Wrapper...
set "DOWNLOAD_URL=https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar"
set "WRAPPER_JAR=%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar"

powershell -Command "& { Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%WRAPPER_JAR%' }" 2>nul
if not exist "%WRAPPER_JAR%" (
    echo Failed to download Maven Wrapper
    exit /b 1
)

:runWrapper
"%JAVA_HOME%\bin\java.exe" -classpath "%MAVEN_PROJECTBASEDIR%\.mvn\wrapper\maven-wrapper.jar" org.apache.maven.wrapper.MavenWrapperMain %MAVEN_CMD_LINE_ARGS%
