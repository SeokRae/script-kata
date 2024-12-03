#!/bin/sh

# 인증서 유효성 검사 (유효기간, 남은 유효일)
check_certificate_validity() {
    local domain="$1"
    local port="$2"

    local cert_dates=$(echo | openssl s_client -servername "$domain" \
                   -connect "$domain:$port" 2>/dev/null | \
                   openssl x509 -noout -dates 2>/dev/null)

    if [ -z "$cert_dates" ]; then
        echo "CONNECTION_ERROR|CONNECTION_ERROR|0"
        return
    fi

    local not_before=$(echo "$cert_dates" | grep "notBefore=" | cut -d'=' -f2)
    local not_after=$(echo "$cert_dates" | grep "notAfter=" | cut -d'=' -f2)
    
    local today=$(date +%s)
    local expire_date=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" "+%s" 2>/dev/null)
    local days_left=$(( (expire_date - today) / 86400 ))

    echo "$not_before|$not_after|$days_left"
}

verify_certificate_chain() {
    local domain="$1"
    local port="$2"
    
    local cert_chain
    cert_chain=$(echo | openssl s_client -connect "$domain:$port" -showcerts 2>/dev/null)
    
    if [ -z "$cert_chain" ]; then
        echo "CONNECTION_ERROR|CONNECTION_ERROR|CONNECTION_ERROR"
        return
    fi

    local chain_status="1"
    if echo "$cert_chain" | grep -q "Verify return code: 0 (ok)"; then
        chain_status="0"
    fi

    local chain_count=0
    local cert_data=""
    
    while IFS= read -r line; do
        if [[ "$line" == "Certificate chain" ]]; then
            in_chain=true
            continue
        elif [[ "$line" == "---" && "$in_chain" == true ]]; then
            in_chain=false
            continue
        fi
        
        if [ "$in_chain" = true ]; then
            if echo "$line" | grep -qE "^[[:space:]]*[0-9]+[[:space:]]s:"; then
                if [ $chain_count -gt 0 ]; then
                    cert_data="${cert_data};"
                fi
                local cert_num=$(echo "$line" | sed -nE 's/^[[:space:]]*([0-9]+)[[:space:]]s:.*/\1/p')
                local subject=$(echo "$line" | sed -nE 's/^[[:space:]]*[0-9]+[[:space:]]s:(.*)/\1/p')
                cert_data="${cert_data}${cert_num}|${subject}"
            elif echo "$line" | grep -qE "^[[:space:]]*i:"; then
                local issuer=$(echo "$line" | sed -nE 's/^[[:space:]]*i:(.*)/\1/p')
                cert_data="${cert_data}|${issuer}"
            elif echo "$line" | grep -qE "^[[:space:]]*a:PKEY:"; then
                local algo=$(echo "$line" | sed -nE 's/^[[:space:]]*a:PKEY:[[:space:]]([^,]+),.*/\1/p')
                local key_size=$(echo "$line" | sed -nE 's/^[[:space:]]*a:PKEY:[^,]+,[[:space:]]([0-9]+)[[:space:]]\(bit\).*/\1/p')
                local sig_algo=$(echo "$line" | sed -nE 's/.*sigalg:[[:space:]]([^[:space:]]+).*/\1/p')
                cert_data="${cert_data}|${algo}|${key_size}|${sig_algo}"
                ((chain_count++))
            fi
        fi
    done <<< "$cert_chain"

#    synchronized_log "Chain data parsed: ${cert_data}"
#    synchronized_log "Chain count: ${chain_count}"

    # 구조화된 데이터 반환:
    # cert_num|subject|issuer|algo|key_size|sig_algo;cert_num|subject|issuer|algo|key_size|sig_algo|chain_status
    echo "${cert_data}|${chain_status}"
}

check_certificate_algorithm() {
    local domain="$1"
    local port="$2"
    
    # 인증서 알고리즘 정보 추출
    local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:$port" 2>/dev/null | openssl x509 -noout -text)
    
    if [ -z "$cert_info" ]; then
        echo "CONNECTION_ERROR|CONNECTION_ERROR|CONNECTION_ERROR"
        return
    fi
    
    # 모든 알고리즘 정보 추출
    local key_algorithms=$(echo "$cert_info" | grep "Public Key Algorithm:" | cut -d':' -f2 | tr -d ' ' | paste -sd "," -)
    local key_sizes=$(echo "$cert_info" | grep -o '[0-9]\+ bit' | cut -d' ' -f1 | paste -sd "," -)
    local sig_algorithms=$(echo "$cert_info" | grep "Signature Algorithm:" | cut -d':' -f2 | tr -d ' ' | paste -sd "," -)
    
    # 결과 반환
    if [ -n "$key_algorithms" ] && [ -n "$key_sizes" ] && [ -n "$sig_algorithms" ]; then
        echo "$key_algorithms|$key_sizes|$sig_algorithms"
    else
        echo "PARSE_ERROR|PARSE_ERROR|PARSE_ERROR"
    fi
}