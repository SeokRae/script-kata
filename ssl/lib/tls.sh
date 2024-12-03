#!/bin/sh

check_tls_versions() {
    local domain="$1"
    local port="$2"
    local supported_tls_versions=()
    local security_level="✅"

    # TLS 버전 확인
    for version in "${TLS_VERSIONS[@]}"; do
        IFS=':' read -r option display_name <<< "$version"

        if openssl s_client -help 2>&1 | grep -q -- "-$option"; then
            local cmd="echo | openssl s_client -connect \"$domain:$port\" -\"$option\" 2>/dev/null"
            local raw_result=$(eval "$cmd")

            if echo "$raw_result" | grep -q "CONNECTED"; then
                supported_tls_versions+=("$display_name")
                case "$display_name" in
                    "TLS 1.0"|"TLS 1.1")
                        security_level="⚠️"
                        ;;
                esac
            fi
        fi
    done

    # 반환 타입: 지원하는 TLS 버전|보안 수준
    echo "${supported_tls_versions[*]:-없음}|$security_level"
}

check_cipher_suites() {
    local domain="$1"
    local port="$2"

    local cipher_output=$(echo | openssl s_client -connect "${domain}:${port}" -cipher "ALL:COMPLEMENTOFALL" 2>/dev/null)

    if [ -n "$cipher_output" ]; then
        local cipher_list=$(echo "$cipher_output" | grep -A 1 "Cipher is" | tail -n 1)
        local protocol=$(echo "$cipher_output" | grep "Protocol" | cut -d':' -f2 | tr -d ' ')
        # 반환 타입: 프로토콜|암호화 알고리즘|0
        echo "$protocol|$cipher_list|0"
    else
        # 오류 반환 타입: 프로토콜|암호화 알고리즘|1
        echo "연결 실패|연결 실패|1"
    fi
}

# TLS 보안 수준 검사
check_tls_security() {
    local domain="$1"
    local port="$2"

    local security_warnings=""
    local tls_info=$(check_tls_versions "$domain" "$port")
    local cipher_info=$(check_cipher_suites "$domain" "$port")

    # TLS 1.0/1.1 사용 검사
    if [[ $tls_info == *"✅ TLS 1.0"* ]] || [[ $tls_info == *"✅ TLS 1.1"* ]]; then
        security_warnings+="⚠️  취약한 TLS 버전(1.0/1.1) 사용 중\n"
    fi

    # TLS 1.3 미지원 검사
    if [[ $tls_info != *"✅ TLS 1.3"* ]]; then
        security_warnings+="⚠️  TLS 1.3 미지원\n"
    fi

    # 취약한 암호화 스위트 검사
    IFS='|' read -r protocol cipher_list status <<< "$cipher_info"
    if [[ $cipher_list == *"RC4"* ]] || [[ $cipher_list == *"DES"* ]] || [[ $cipher_list == *"MD5"* ]]; then
        security_warnings+="⚠️  취약한 암호화 알고리즘 사용 가능\n"
    fi

    echo "${security_warnings%\\n}"  # 마지막 개행 제거
}