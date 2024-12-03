#!/bin/sh

calculate_days_left() {
    local end_date="$1"
    local end_epoch
    local now_epoch=$(date "+%s")
    
    if [ "$(uname)" = "Darwin" ]; then
        end_epoch=$(date -j -f "%b %e %H:%M:%S %Y %Z" "$end_date" "+%s" 2>/dev/null)
    else
        end_epoch=$(date -d "$end_date" "+%s" 2>/dev/null)
    fi
    
    if [ -n "$end_epoch" ]; then
        echo $(( (end_epoch - now_epoch) / 86400 ))
    else
        echo "0"
    fi
}

#print_commands() {
#    local domain="$1"
#    local port="$2"
#
#    # 명령어 목록 헤더
#    log_only "▶ 실행 명령어 목록 ($domain:$port)"
#    log_only "──────────────────────────────────────────────"
#
#    # 1. 인증서 유효성 검사
#    local cmd="echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -dates"
#    local result=$(eval "$cmd")
#    log_command_with_result "$cmd" "$result"
#
#    # 2. 인증서 체인 검사
#    cmd="echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -issuer -subject"
#    result=$(eval "$cmd")
#    log_command_with_result "$cmd" "$result"
#
#    # 3. TLS 버전 검사
#    for version in "${TLS_VERSIONS[@]}"; do
#        IFS=':' read -r option display_name <<< "$version"
#        cmd="echo | openssl s_client -connect \"$domain:$port\" -\"$option\" 2>/dev/null"
#        result=$(eval "$cmd")
#        log_command_with_result "$cmd" "$result"
#    done
#
#    # 4. 인증서 알고리즘 검사
#    cmd="echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -text"
#    result=$(eval "$cmd")
#    log_command_with_result "$cmd" "$result"
#
#    # 5. 도메인 일치 여부 검사
#    cmd="echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -text"
#    result=$(eval "$cmd")
#    log_command_with_result "$cmd" "$result"
#
#    # 6. 암호화 스위트 검사
#    cmd="echo | openssl s_client -connect \"$domain:$port\" -cipher 'ALL:COMPLEMENTOFALL' 2>/dev/null"
#    result=$(eval "$cmd")
#    log_command_with_result "$cmd" "$result"
#}