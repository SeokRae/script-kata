#!/bin/sh

# 기본 디렉토리 설정
# 현재 스크립트의 상위 디렉토리를 BASE_DIR로 설정
BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# 임시 파일이 저장될 TMP 디렉토리 설정
TMP_DIR="${BASE_DIR}/tmp"
# SSL 관련 로그를 저장할 LOG 디렉토리 설정
LOG_DIR="${BASE_DIR}/ssl_logs"

# 타임아웃과 재시도 설정
CONNECT_TIMEOUT=5
MAX_RETRIES=3
RETRY_DELAY=2

# 병렬 처리 설정
MAX_PARALLEL=20

# TLS 버전 정의
TLS_VERSIONS=(
    "tls1:TLS 1.0"
    "tls1_1:TLS 1.1"
    "tls1_2:TLS 1.2"
    "tls1_3:TLS 1.3"
)