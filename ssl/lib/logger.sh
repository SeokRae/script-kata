#!/bin/bash

# 로그 관련 변수들
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # 스크립트의 상위 디렉토리를 BASE_DIR로 설정
LOG_DIR="${BASE_DIR}/ssl_logs"                              # SSL 관련 로그 파일을 저장할 디렉토리 설정
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')                          # 로그 파일에 사용할 타임스탬프 형식 (YYYYMMDD_HHMMSS)
LOG_FILE="${LOG_DIR}/ssl_check_${TIMESTAMP}.log"            # 로그 파일 경로 생성
MUTEX_FILE="/tmp/ssl_check.mutex"                          # 동기화 제어를 위한 뮤텍스 파일 경로 설정

# 뮤텍스 락 초기화
init_mutex() {
    touch "$MUTEX_FILE"
}

# 뮤텍스 락 획득
acquire_lock() {
    local max_attempts=50
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if ln "$MUTEX_FILE" "${MUTEX_FILE}.lock" 2>/dev/null; then
            return 0
        fi
        sleep 0.1
        attempt=$((attempt + 1))
    done
    echo "Failed to acquire lock after $max_attempts attempts" >> "$LOG_FILE"
    return 1
}

# 뮤텍스 락 해제
release_lock() {
    rm -f "${MUTEX_FILE}.lock"
}

# 통합 로그 출력 함수
log_message() {
    local target="$1"    # 출력 대상: console, file, both
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local formatted_message="[${timestamp}] $message"

    case "$target" in
        console)
            echo "$formatted_message"
            ;;
        file)
            acquire_lock
            echo "$formatted_message" >> "$LOG_FILE"
            release_lock
            ;;
        both)
            acquire_lock
            echo "$formatted_message" | tee -a "$LOG_FILE"
            release_lock
            ;;
        *)
            echo "Invalid log target: $target" >> "$LOG_FILE"
            ;;
    esac
}

# 콘솔과 로그 파일 모두에 출력
output() {
    local message="$1"
    echo "[${timestamp}] $message" >> "$LOG_FILE"
}

# 명령어와 결과를 로그에 기록
log_command_with_result() {
    local command="$1"
    local result="$2"
    
    synchronized_log "실행 명령어: ${command}"
    synchronized_log "실행 결과: ${result}"
    synchronized_log "──────────────────────────────────────────────"
}

# 동기화된 로그 출력 (타임스탬프 포함)
synchronized_log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    acquire_lock
    {
        # 파일과 콘솔 동시에 출력
        echo "[${timestamp}] $message" | tee -a "$LOG_FILE"
    }
    release_lock
}

# 명령어 실행 및 로그 기록
log_command() {
    local command="$1"
    local output

    output=$(eval "$command" 2>&1)

    log_message both "▶ 실행 명령어: $command"
    if [ -n "$output" ]; then
        log_message both "▶ 실행 결과:"
        while IFS= read -r line; do
            log_message both "$line"
        done <<< "$output"
    fi
    log_message both "──────────────────────────────────────────────"
}

# 로그 초기화
init_log() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    init_mutex
    trap 'rm -f "$MUTEX_FILE"' EXIT
}

# 초기화 호출
init_log