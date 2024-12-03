#!/bin/sh
# test_logger.sh

# 의존성 로드
. ./config/settings.sh
. ./lib/logger.sh
. ./lib/permissions.sh

# 초기화
init_permissions

# 테스트 케이스
echo "Logger 테스트 시작..."
synchronized_log "테스트 메시지 1"
synchronized_log "테스트 메시지 2" false true
log_command "ls -la"

echo "로그 파일 확인: $LOG_FILE"
cat "$LOG_FILE"