#!/bin/sh
# Maven Wrapper launch script for Unix
# ----------------------------------------------------------------------------

MAVEN_PROJECTBASEDIR="${MAVEN_BASEDIR:-$(cd "$(dirname "$0")" && pwd)}"
MAVEN_CMD_LINE_ARGS="$@"

WRAPPER_JAR="$MAVEN_PROJECTBASEDIR/.mvn/wrapper/maven-wrapper.jar"

if [ ! -f "$WRAPPER_JAR" ]; then
    echo "Downloading Maven Wrapper..."
    DOWNLOAD_URL="https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.2.0/maven-wrapper-3.2.0.jar"
    curl -fsSL "$DOWNLOAD_URL" -o "$WRAPPER_JAR" || { echo "Failed to download Maven Wrapper"; exit 1; }
fi

exec java -classpath "$WRAPPER_JAR" org.apache.maven.wrapper.MavenWrapperMain $MAVEN_CMD_LINE_ARGS
