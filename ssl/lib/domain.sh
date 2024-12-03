#!/bin/sh

# 공통 명령 실행 및 결과 로깅 함수
#execute_and_log() {
#    local cmd="$1"
#    local step_name="$2"
#    local task_log="$3"
#
#    # 명령 실행
#    local result=$(eval "$cmd" 2>&1)
#
#    # 명령과 결과를 로그에 기록
#    log_command_with_result "$cmd" "$result" "$step_name" "$task_log"
#
#    echo "$result" # 결과 반환
#}

# 인증서 검사 리팩토링된 함수
#verify_domain() {
#    local domain="$1"
#    local port="$2"
#    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
#    local task_log="${TMP_DIR}/task_${domain}_${port}.log"
#
#    log_only "▶ 실행 명령어 목록 ($domain:$port)"
#
#    # 각 단계별 명령어와 결과 기록
#    local cert_info chain_info tls_info algo_info domain_info cipher_info
#
#    # 1. 인증서 유효성 검사
#    cert_info=$(execute_and_log "echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -dates" \
#                                 "인증서 유효성 검사" "$task_log")
#    cert_info=$(check_certificate_validity "$domain" "$port")
#
#    # 2. 인증서 체인 검사
#    chain_info=$(execute_and_log "echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" -showcerts 2>/dev/null" \
#                                  "인증서 체인 검사" "$task_log")
#    chain_info=$(verify_certificate_chain "$domain" "$port")
#
#    # 3. TLS 버전 검사
#    tls_info=$(execute_and_log "echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null" \
#                                "TLS 버전 검사" "$task_log")
#    tls_info=$(check_tls_versions "$domain" "$port")
#
#    # 4. 알고리즘 검사
#    algo_info=$(execute_and_log "echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -text" \
#                                 "알고리즘 검사" "$task_log")
#    algo_info=$(check_certificate_algorithm "$domain" "$port")
#
#    # 5. 도메인 일치 여부 검사
#    domain_info=$(execute_and_log "echo | openssl s_client -servername \"$domain\" -connect \"$domain:$port\" 2>/dev/null | openssl x509 -noout -text" \
#                                   "도메인 일치 여부 검사" "$task_log")
#    domain_info=$(check_domain_match "$domain" "$port")
#
#    # 6. 암호화 스위트 검사
#    cipher_info=$(execute_and_log "echo | openssl s_client -connect \"$domain:$port\" -cipher 'ALL:COMPLEMENTOFALL' 2>/dev/null" \
#                                   "암호화 스위트 검사" "$task_log")
#    cipher_info=$(check_cipher_suites "$domain" "$port")
#
#    # 최종 결과 출력
#    print_domain_result "$domain" "$port" "$cert_info" "$chain_info" "$tls_info" \
#                       "$algo_info" "$domain_info" "$cipher_info" "$timestamp" \
#                       >> "$task_log"
#}

verify_domain() {
    local domain="$1"
    local port="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local task_log="${TMP_DIR}/task_${domain}_${port}.log"

    log_message console "▶ 실행 명령어 목록 ($domain:$port)"

    # 결과 저장 변수 초기화
    local cert_info chain_info tls_info algo_info domain_info cipher_info

    # 1. 인증서 유효성 검사
    cert_info=$(check_certificate_validity "$domain" "$port")
    if [[ -z "$cert_info" ]]; then
        log_message both "인증서 유효성 검사를 실패했습니다."
        return 1
    fi

    # 2. 인증서 체인 검사
    chain_info=$(verify_certificate_chain "$domain" "$port")
    if [[ -z "$chain_info" ]]; then
        log_message both "인증서 체인 검사를 실패했습니다."
        return 1
    fi

    # 3. TLS 버전 검사
    tls_info=$(check_tls_versions "$domain" "$port")
    if [[ -z "$tls_info" ]]; then
        log_message both "TLS 버전 검사를 실패했습니다."
        return 1
    fi

    # 4. 알고리즘 검사
    algo_info=$(check_certificate_algorithm "$domain" "$port")
    if [[ -z "$algo_info" ]]; then
        log_message both "알고리즘 검사를 실패했습니다."
        return 1
    fi

    # 5. 도메인 일치 여부 검사
    domain_info=$(check_domain_match "$domain" "$port")
    if [[ -z "$domain_info" ]]; then
        log_message both "도메인 일치 여부 검사를 실패했습니다."
        return 1
    fi

    # 6. 암호화 스위트 검사
    cipher_info=$(check_cipher_suites "$domain" "$port")
    if [[ -z "$cipher_info" ]]; then
        log_message both "암호화 스위트 검사를 실패했습니다."
        return 1
    fi

    # 최종 결과 출력
    print_domain_result "$domain" "$port" "$cert_info" "$chain_info" "$tls_info" \
                        "$algo_info" "$domain_info" "$cipher_info" "$timestamp" \
                        >> "$task_log"
}

print_domain_result() {
    local domain="$1"
    local port="$2"
    local cert_info="$3"
    local chain_info="$4"
    local tls_info="$5"
    local algo_info="$6"
    local domain_info="$7"
    local cipher_info="$8"
    local timestamp="$9"

    local separator="================================================================"
    local sub_separator="----------------------------------------------------------------"

    # synchronized_log 대신 echo 사용
    log_message console "$separator"
    log_message console "🔍 도메인 검증 결과: $domain:$port"
    log_message console "⏰ 검증 시간: $timestamp"
    log_message console "$separator"

    # 1. 인증서 유효 기간 출력
    print_cert_validity "$cert_info" "$sub_separator"

    # 2. 인증서 체인 정보 출력
    print_cert_chain_info "$chain_info" "$sub_separator"

    # 3. TLS 프로토콜 지원 현황 출력
    print_tls_info "$tls_info" "$sub_separator"

    # 4. 인증서 알고리즘 정보 출력
    print_algo_info "$algo_info" "$sub_separator"

    # 5. 도메인 일치 여부 분석 출력
    analyze_domain_match "$domain" "$domain_info" "$sub_separator"

    # 6. 암호화 스위트 정보 출력
    print_cipher_info "$cipher_info" "$sub_separator"
}

# 인증서 유효 기간 출력
print_cert_validity() {
    local cert_info="$1"
    local sub_separator="$2"

    IFS='|' read -r start_date end_date days_left <<< "$cert_info"
    log_message console "1️⃣ 인증서 유효 기간"
    log_message console "   ▶ 시작일: $start_date"
    log_message console "   ▶ 만료일: $end_date"
    if [[ -n "$days_left" ]] && [[ "$days_left" -lt 30 ]]; then
        log_message console "   ▶ 남은 기간: ⚠️  $days_left 일 (만료 임박)"
    elif [[ -n "$days_left" ]]; then
        log_message console "   ▶ 남은 기간: ✅ $days_left 일"
    fi
    log_message console "$sub_separator"
}

# 인증서 체인 정보 출력
print_cert_chain_info() {
    local chain_info="$1"
    local sub_separator="$2"

    log_message console "2️⃣ 인증서 체인 정보"
    if [[ -n "$chain_info" ]]; then
        chain_status="${chain_info##*|}"
        cert_data="${chain_info%|*}"
        log_message console "   ▶ 인증서 체인 구조:"

        IFS=';' read -ra certs <<< "$cert_data"
        for cert in "${certs[@]}"; do
            IFS='|' read -r cert_num subject issuer algo key_size sig_algo <<< "$cert"
            if [[ "$cert_num" == "0" ]]; then
                log_message console "   📜 최종 서버 인증서 (End Entity):"
            else
                log_message console "   📜 중간 인증서 ${cert_num} (Intermediate CA):"
            fi
            log_message console "      ├─ Subject: ${subject}"
            log_message console "      ├─ Issuer: ${issuer}"
            log_message console "      ├─ 공개키: ${algo} (${key_size} bits)"
            log_message console "      └─ 서명 알고리즘: ${sig_algo}"
            if [[ "$cert_num" != "$((${#certs[@]}-1))" ]]; then
                log_message console "      │"
                log_message console "      ▼"
            fi
        done

        log_message console "   📋 체인 검증 결과:"
        if [[ "$chain_status" == "0" ]]; then
            log_message console "      ✅ 신뢰할 수 있는 인증서 체인"
            log_message console "      ├─ 체인 길이: ${#certs[@]} 단계"
            log_message console "      └─ 검증 상태: 정상"
        else
            log_message console "      ⚠️  신뢰할 수 없는 인증서 체인"
            log_message console "      ├─ 체인 길이: ${#certs[@]} 단계"
            log_message console "      └─ 검증 상태: 실패"
        fi
    else
        log_message console "   ▶ 인증서 체인 정보를 가져올 수 없습니다"
    fi
    log_message console "$sub_separator"
}

# TLS 프로토콜 지원 정보 출력
print_tls_info() {
    local tls_info="$1"
    local sub_separator="$2"

    log_message console "3️⃣ TLS 프로토콜 지원 현황"
    if [[ -n "$tls_info" ]]; then
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                clean_line=$(echo "$line" | sed 's/^\[[0-9: -]*\] *//')
                log_message console "   $clean_line"
            fi
        done <<< "$tls_info"
    else
        log_message console "   ▶ TLS 정보를 가져올 수 없습니다"
    fi
    log_message console "$sub_separator"
}

# 알고리즘 정보 출력
print_algo_info() {
    local algo_info="$1"
    local sub_separator="$2"

    log_message console "4️⃣ 인증서 알고리즘 정보"
    if [[ "$algo_info" == *"CONNECTION_ERROR"* ]]; then
        log_message console "   ▶ 연결 오류: 알고리즘 정보를 가져올 수 없습니다"
    elif [[ "$algo_info" == *"PARSE_ERROR"* ]]; then
        log_message console "   ▶ 파싱 오류: 알고리즘 정보를 분석할 수 없습니다"
    elif [[ -n "$algo_info" ]]; then
        IFS='|' read -r key_algorithms key_sizes sig_algorithms <<< "$algo_info"
        log_message console "   ▶ 공개키 알고리즘:"
        for algo in $(echo "$key_algorithms" | tr ',' '\n'); do
            log_message console "       - $algo"
        done
        log_message console "   ▶ 키 길이:"
        for size in $(echo "$key_sizes" | tr ',' '\n'); do
            log_message console "       - ${size}bit"
        done
        log_message console "   ▶ 서명 알고리즘:"
        for sig in $(echo "$sig_algorithms" | tr ',' '\n'); do
            log_message console "       - $sig"
        done
    fi
    log_message console "$sub_separator"
}

# 6. 암호화 스위트 정보
print_cipher_info() {
    local cipher_info="$1"
    local timestamp="$2"

    log_message console "6️⃣ 암호화 스위트 정보"
    if [[ "$cipher_info" == *"연결 실패"* ]]; then
        log_message console "   ▶ 연결 오류: 암호화 스위트 정보를 가져올 수 없습니다"
        return
    fi

    IFS='|' read -r protocol cipher_list status <<< "$cipher_info"
    [[ -n "$protocol" ]] && log_message console "   ▶ 프로토콜 버전: $protocol"

    if [[ -n "$cipher_list" ]]; then
        log_message console "   ▶ 사용 중인 암호화 스위트:"
        analyze_cipher_suites "$cipher_list" "$timestamp"
    fi
}

check_domain_match() {
    local domain="$1"
    local port="$2"

    local cert_info
    cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null | openssl x509 -noout -text)

    local cn=$(echo "$cert_info" | grep "Subject:" | grep -o "CN=.*" | cut -d'=' -f2)
    local san=$(echo "$cert_info" | grep -A1 "Subject Alternative Name" | tail -n1 | tr -d ' ')

    if [ -n "$cn" ] && [ -n "$san" ]; then
        echo "$cn|$san|0"
    else
        echo "ERROR|ERROR|1"
    fi
}

# 암호화 스위트 분석 함수
analyze_cipher_suites() {
    local cipher_list="$1"
    local timestamp="$2"

    if [[ "$cipher_list" == *"TLS_"* ]]; then
        case "$cipher_list" in
            *"TLS_AES_256_GCM"*) log_message console "       ✅ $cipher_list (TLS 1.3 - 매우 안전)" ;;
            *"TLS_AES_128_GCM"*) log_message console "       ✅ $cipher_list (TLS 1.3 - 안전)" ;;
            *"TLS_CHACHA20"*) log_message console "       ✅ $cipher_list (TLS 1.3 - 매우 안전)" ;;
            *) log_message console "       ✅ $cipher_list (TLS 1.3 암호화 스위트)" ;;
        esac
    else
        case "$cipher_list" in
            *"ECDHE"*"AES_256_GCM"*) log_message console "       ✅ $cipher_list (Perfect Forward Secrecy + 강력한 암호화)" ;;
            *"ECDHE"*"AES_128_GCM"*) log_message console "       ✅ $cipher_list (Perfect Forward Secrecy + 안전한 암호화)" ;;
            *"ECDHE"*"CHACHA20"*) log_message console "       ✅ $cipher_list (Perfect Forward Secrecy + 현대적 암호화)" ;;
            *"AES_256_GCM"*) log_message console "       ✅ $cipher_list (강력한 암호화)" ;;
            *"AES_128_GCM"*) log_message console "       ✅ $cipher_list (안전한 암호화)" ;;
            *) log_message console "       ⚠️  $cipher_list (보안팀 검토 필요)" ;;
        esac
    fi
}

analyze_domain_match() {
    local domain="$1"
    local domain_info="$2"
    local timestamp="$3"

    IFS='|' read -r cert_domain san_list status <<< "$domain_info"

    log_message console "5️⃣ 도메인 일치 여부"
    log_message console "   ▶ 인증서 발급 도메인: $cert_domain"

    if [[ -n "$san_list" ]]; then
        log_message console "   ▶ 대체 도메인 목록:"
        IFS=',' read -ra sans <<< "$san_list"
        for san in "${sans[@]}"; do
            san=$(echo "$san" | sed 's/DNS://g' | tr -d ' ')
            if [[ "$san" == "$domain" ]]; then
                log_message console "       ✅ $san (요청 도메인과 일치)"
            else
                log_message console "       - $san"
            fi
        done

        if [[ "$cert_domain" == "$domain" ]] || [[ "$san_list" == *"$domain"* ]]; then
            log_message console "   ▶ 검증 결과: ✅ 도메인 일치 확인"
        else
            log_message console "   ▶ 검증 결과: ❌ 도메인 불일치 (보안 주의 필요)"
            log_message console "      ⚠️  인증서가 요청한 도메인($domain)에 대해 유효하지 않습니다."
        fi
    else
        log_message console "   ▶ 대체 도메인 정보 없음"
        if [[ "$cert_domain" == "$domain" ]]; then
            log_message console "   ▶ 검증 결과: ✅ 도메인 일치 확인"
        else
            log_message console "   ▶ 검증 결과: ❌ 도메인 불일치 (보안 주의 필요)"
            log_message console "      ⚠️  인증서가 요청한 도메인($domain)에 대해 유효하지 않습니다."
        fi
    fi
    log_message console "$sub_separator"
}