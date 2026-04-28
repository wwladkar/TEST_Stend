#!/usr/bin/env bash
# ============================================================
#  TEST Stend — unified management script (Linux/Mac)
#  Usage:
#    ./stend.sh           — build + start
#    ./stend.sh start     — start without build
#    ./stend.sh stop      — stop all services
#    ./stend.sh status    — check status
#    ./stend.sh clean     — stop + delete DB + rebuild
#    ./stend.sh restart   — stop + start
# ============================================================
set -euo pipefail

# --- Configuration (auto-detected) ---
WORKDIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$WORKDIR/frontend"
LOG_DIR="$WORKDIR/logs"
SPRING_PROFILE=""   # empty = H2 default; set to "pg" for PostgreSQL

# Auto-detect Java
if [ -n "${JAVA_HOME:-}" ]; then
    JAVA_EXE="$JAVA_HOME/bin/java"
else
    JAVA_EXE="$(command -v java 2>/dev/null || true)"
fi

# Auto-detect Maven: Maven Wrapper > MAVEN_HOME > system
if [ -f "$WORKDIR/mvnw" ]; then
    MVN_CMD="$WORKDIR/mvnw"
elif [ -n "${MAVEN_HOME:-}" ]; then
    MVN_CMD="$MAVEN_HOME/bin/mvn"
else
    MVN_CMD="$(command -v mvn 2>/dev/null || true)"
fi

declare -A SERVICES
SERVICE_NAMES=("Auth Service" "Core Service" "API Gateway")
SERVICE_PORTS=(8081 8082 8080)
SERVICE_JARS=(
    "auth-service/target/auth-service-1.0.0-SNAPSHOT.jar"
    "core-service/target/core-service-1.0.0-SNAPSHOT.jar"
    "api-gateway/target/api-gateway-1.0.0-SNAPSHOT.jar"
)
FRONTEND_PORT=3000

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# --- Load and validate .env ---
load_env() {
    local env_file="$WORKDIR/.env"
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}[ERROR] .env not found. Run: cp .env.example .env${NC}"
        exit 1
    fi
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key="$(echo "$key" | xargs)"
        value="$(echo "$value" | xargs)"
        export "$key=$value"
    done < "$env_file"

    # Validate JWT_SECRET
    local placeholder="your-random-secret-at-least-32-bytes-long!!"
    if [ -z "${JWT_SECRET:-}" ] || [ "$JWT_SECRET" = "$placeholder" ]; then
        echo -e "${RED}[ERROR] JWT_SECRET is not set or has placeholder value. Edit .env!${NC}"
        exit 1
    fi
}

# --- Check if a TCP port is open ---
test_port() {
    local port=$1
    if command -v ss &>/dev/null; then
        ss -tln 2>/dev/null | grep -q ":${port} "
    elif command -v lsof &>/dev/null; then
        lsof -i :"$port" -sTCP:LISTEN &>/dev/null
    else
        netstat -tln 2>/dev/null | grep -q ":${port} "
    fi
}

# --- Wait for a TCP port ---
wait_for_port() {
    local port=$1
    local timeout_sec=${2:-30}
    local deadline=$((SECONDS + timeout_sec))
    while [ $SECONDS -lt $deadline ]; do
        if test_port "$port"; then return 0; fi
        sleep 0.5
    done
    return 1
}

# ========================= BUILD =========================
do_build() {
    echo ""
    echo -e "${CYAN}[BUILD] Assembling project...${NC}"

    if [ -z "$JAVA_EXE" ] || [ ! -f "$JAVA_EXE" ]; then
        echo -e "${RED}  [ERROR] Java not found. Set JAVA_HOME or add java to PATH.${NC}"
        exit 1
    fi
    if [ -z "$MVN_CMD" ] || [ ! -f "$MVN_CMD" ]; then
        echo -e "${RED}  [ERROR] Maven not found. Install Maven or use Maven Wrapper (mvnw).${NC}"
        exit 1
    fi

    export JAVA_HOME
    echo -e "${GRAY}  Java:   $JAVA_EXE${NC}"
    echo -e "${GRAY}  Maven:  $MVN_CMD${NC}"

    if ! "$MVN_CMD" clean package -DskipTests -q; then
        echo -e "${RED}  [ERROR] Build failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}  Build OK${NC}"
}

# ========================= START =========================
do_start() {
    for i in "${!SERVICE_NAMES[@]}"; do
        local jar="$WORKDIR/${SERVICE_JARS[$i]}"
        if [ ! -f "$jar" ]; then
            echo -e "${RED}[ERROR] JAR not found: ${SERVICE_JARS[$i]}. Run ./stend.sh to build.${NC}"
            exit 1
        fi
    done

    load_env
    mkdir -p "$LOG_DIR"

    echo ""
    echo -e "${CYAN}[START] Launching services...${NC}"

    for i in "${!SERVICE_NAMES[@]}"; do
        local name="${SERVICE_NAMES[$i]}"
        local port="${SERVICE_PORTS[$i]}"
        local jar="$WORKDIR/${SERVICE_JARS[$i]}"
        local log_name="$(echo "$name" | tr -d ' ')"

        if test_port "$port"; then
            echo -e "  ${YELLOW}$name (:${port}) already running${NC}"
            continue
        fi

        echo -e "  $name (:${port})...\c"
        local profile_arg=""
        [ -n "$SPRING_PROFILE" ] && profile_arg="-Dspring.profiles.active=$SPRING_PROFILE"

        "$JAVA_EXE" $profile_arg -jar "$jar" \
            > "$LOG_DIR/${log_name}.log" 2> "$LOG_DIR/${log_name}-error.log" &
        local pid=$!

        if wait_for_port "$port" 30; then
            echo -e " ${GREEN}OK${NC}"
        else
            echo -e " ${RED}FAILED (check logs/)${NC}"
        fi
    done

    if test_port "$FRONTEND_PORT"; then
        echo -e "  ${YELLOW}Frontend (:3000) already running${NC}"
    else
        echo -e "  Frontend (:3000)...\c"
        (cd "$FRONTEND_DIR" && npm run dev > "$LOG_DIR/frontend.log" 2>&1) &
        if wait_for_port "$FRONTEND_PORT" 15; then
            echo -e " ${GREEN}OK${NC}"
        else
            echo -e " ${RED}FAILED${NC}"
        fi
    fi

    do_status
}

# ========================= STOP =========================
do_stop() {
    echo ""
    echo -e "${CYAN}[STOP] Stopping all services...${NC}"
    local stopped=0

    for jar_keyword in "auth-service" "core-service" "api-gateway"; do
        local pids=$(pgrep -f "$jar_keyword" 2>/dev/null || true)
        for pid in $pids; do
            kill "$pid" 2>/dev/null || true
            ((stopped++)) || true
        done
    done

    # Stop Vite dev server
    local vite_pids=$(pgrep -f "vite" 2>/dev/null || true)
    for pid in $vite_pids; do
        kill "$pid" 2>/dev/null || true
        ((stopped++)) || true
    done

    if [ $stopped -eq 0 ]; then
        echo -e "  ${YELLOW}No services running${NC}"
    else
        echo -e "  ${GREEN}Stopped $stopped process(es)${NC}"
    fi
}

# ========================= STATUS =========================
do_status() {
    echo ""
    echo -e "${CYAN}[STATUS]${NC}"
    local all_up=true

    for i in "${!SERVICE_NAMES[@]}"; do
        local name="${SERVICE_NAMES[$i]}"
        local port="${SERVICE_PORTS[$i]}"
        local up=false
        test_port "$port" && up=true

        if $up; then
            echo -e "  $(printf '%-14s' "$name") :${port}    UP  "
        else
            echo -e "  $(printf '%-14s' "$name") :${port}   DOWN "
            all_up=false
        fi
    done

    local f_up=false
    test_port "$FRONTEND_PORT" && f_up=true
    if $f_up; then
        echo -e "  $(printf '%-14s' "Frontend") :${FRONTEND_PORT}    UP  "
    else
        echo -e "  $(printf '%-14s' "Frontend") :${FRONTEND_PORT}   DOWN "
        all_up=false
    fi

    echo ""
    if $all_up; then
        echo -e "  ${GREEN}All services running: http://localhost:3000${NC}"
    else
        echo -e "  ${YELLOW}Some services are down.${NC}"
    fi
}

# ========================= CLEAN =========================
do_clean() {
    do_stop
    echo ""
    echo -e "${CYAN}[CLEAN] Removing H2 data and logs...${NC}"
    if [ -d "$WORKDIR/data" ]; then
        rm -rf "$WORKDIR/data"
        echo -e "  ${GREEN}H2 data removed${NC}"
    fi
    if [ -d "$LOG_DIR" ]; then
        rm -rf "$LOG_DIR"
        echo -e "  ${GREEN}Logs removed${NC}"
    fi
    echo -e "  Rebuilding..."
    do_build
    echo -e "  ${GREEN}Done. Run: ./stend.sh start${NC}"
}

# ========================= MAIN =========================
action="${1:-build}"

case "$action" in
    build)   do_build; do_start ;;
    start)   do_start ;;
    stop)    do_stop ;;
    restart) do_stop; sleep 3; do_start ;;
    status)  do_status ;;
    clean)   do_clean ;;
    *)       echo -e "${RED}Unknown command: $action\nUsage: ./stend.sh [build|start|stop|restart|status|clean]${NC}"; exit 1 ;;
esac
