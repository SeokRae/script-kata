#!/bin/sh
# test_certificate.sh

# 의존성 로드
. ./config/settings.sh
. ./lib/certificate.sh

# 테스트 도메인
TEST_DOMAIN="naver.com"
TEST_PORT="443"

echo "인증서 검증 테스트 시작..."
echo "도메인: $TEST_DOMAIN:$TEST_PORT"

echo "\n1. 인증서 유효성 검사:"
cert_info=$(check_certificate_validity "$TEST_DOMAIN" "$TEST_PORT")
echo "$cert_info"

echo "\n2. 인증서 체인 검사:"
chain_info=$(verify_certificate_chain "$TEST_DOMAIN" "$TEST_PORT")
echo "$chain_info"

echo "\n3. 인증서 알고리즘 검사:"
algo_info=$(check_certificate_algorithm "$TEST_DOMAIN" "$TEST_PORT")
echo "$algo_info"