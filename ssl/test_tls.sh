#!/bin/sh
# test_tls.sh

# 의존성 로드
. ./config/settings.sh
. ./lib/tls.sh

# 테스트 도메인
TEST_DOMAIN="naver.com"
TEST_PORT="443"

echo "TLS 테스트 시작..."
echo "도메인: $TEST_DOMAIN:$TEST_PORT"

echo "\nTLS 버전 지원 현황:"
tls_info=$(check_tls_versions "$TEST_DOMAIN" "$TEST_PORT")
echo "$tls_info"

echo "\n암호화 스위트 정보:"
cipher_info=$(check_cipher_suites "$TEST_DOMAIN" "$TEST_PORT")
echo "$cipher_info"