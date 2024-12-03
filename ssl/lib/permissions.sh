#!/bin/sh

# 권한 확인 함수
check_permissions() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 로그 디렉토리 권한 확인
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        echo "[${timestamp}] Error: 로그 디렉토리 ($LOG_DIR) 생성 권한이 없습니다."
        exit 1
    fi
    
    # 임시 디렉토리 권한 확인
    if ! mkdir -p "$TMP_DIR" 2>/dev/null; then
        echo "[${timestamp}] Error: 임시 디렉토리 ($TMP_DIR) 생성 권한이 없습니다."
        exit 1
    fi
    
    # 로그 파일 쓰기 권한 확인
    if ! touch "$LOG_FILE" 2>/dev/null; then
        echo "[${timestamp}] Error: 로그 파일 ($LOG_FILE) 생성 권한이 없습니다."
        exit 1
    fi
    
    # 임시 파일 쓰기 권한 확인
    if ! touch "${TMP_DIR}/ssl_check_test_$$" 2>/dev/null; then
        echo "Error: 임시 파일 생성 권한이 없습니다."
        exit 1
    fi
    rm -f "${TMP_DIR}/ssl_check_test_$$"

    # 뮤텍스 디렉토리 권한 확인
    if ! mkdir -p "${TMP_DIR}/mutex_test_$$" 2>/dev/null; then
        echo "Error: 뮤텍스 디렉토리 생성 권한이 없습니다."
        exit 1
    fi
    rmdir "${TMP_DIR}/mutex_test_$$"
}

# 파일 정리 함수
cleanup_files() {
    local pattern="$1"
    if [ -n "$pattern" ]; then
        find "$TMP_DIR" -maxdepth 1 -name "$pattern" -type f -delete 2>/dev/null
        find "$TMP_DIR" -maxdepth 1 -name "$pattern" -type d -delete 2>/dev/null
    fi
}

# 초기 설정 함수
init_permissions() {
    # 임시 디렉토리 생성
    mkdir -p "$TMP_DIR"
    
    # 이전 실행의 임시 파일들 정리
    cleanup_files "ssl_check_*"
    cleanup_files "mutex_*"
    
    # 권한 확인
    check_permissions
    
    # 로그 디렉토리 생성
    mkdir -p "$LOG_DIR"
}