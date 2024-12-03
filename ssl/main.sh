#!/bin/sh

# 공통 함수 정의
load_dependency() {
    local file_path="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Loading $(basename "$file_path")"
    . "$file_path" || { echo "[$(date '+%Y-%m-%d %H:%M:%S')] Failed to load $file_path"; exit 1; }
}

ensure_directory_exists() {
    local dir="$1"
    [ -d "$dir" ] || { synchronized_log "$dir does not exist. Creating directory: $dir"; mkdir -p "$dir"; }
}

process_temp_files() {
    local dir="$1" pattern="$2" action="$3"
    echo "Processing files in $dir matching pattern $pattern"

    # 와일드카드 확장을 위한 nullglob 설정
    shopt -s nullglob 2>/dev/null || true

    for file in "$dir"/$pattern; do
        if [ -f "$file" ]; then
            echo "Processing file: $file"
            [ "$action" = "cat" ] && cat "$file"
            [ "$action" = "delete" ] && rm -f "$file"
        fi
    done
}

calculate_time() {
    local start_time="$1" end_time="$2"
    local total_time=$((end_time - start_time))
    echo "$((total_time / 60))분 $((total_time % 60))초"
}

parse_domain_with_port() {
    local domain_with_port="$1"
    IFS=':' read -r domain port <<< "$domain_with_port"
    port=${port:-443}
    echo "$domain $port"
}

run_in_parallel() {
  local max_parallel="$1"; shift
  local tasks=("$@")
  local pids=() task_logs=()

  for i in "${!tasks[@]}"; do
    task="${tasks[$i]}"
    domain_port=$(echo "$task" | awk '{print $2 "_" $3}')
    task_log="${TMP_DIR}/task_${domain_port}.log"
    task_logs[$i]="$task_log"
#    echo "Starting task: $task (Log file: $task_log)" > "$task_log"
    synchronized_log "Starting task: $task (Log file: $task_log)"
    eval "$task > \"$task_log\" 2>&1 &"
    pids[$i]=$!
  done

  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
        synchronized_log "Task completed successfully: ${tasks[$i]}"
#      echo "Task completed successfully: ${tasks[$i]}" >> "${task_logs[$i]}"
    else
        synchronized_log "Task failed: ${tasks[$i]}"
#      echo "Task failed: ${tasks[$i]}" >> "${task_logs[$i]}"
    fi
  done

  for i in "${!tasks[@]}"; do
    task_log="${task_logs[$i]}"
    if [ -f "$task_log" ]; then
        synchronized_log "Merging log file: $task_log"
        cat "$task_log" >> "$LOG_FILE"
#        rm -f "$task_log"
    else
        synchronized_log "Log file missing: $task_log"
    fi
  done
}

# 의존성 파일 로드
for file in ./config/settings.sh ./config/domains.sh ./lib/*.sh; do
    load_dependency "$file"
done

main() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[${timestamp}] TMP_DIR: $TMP_DIR"
    echo "[${timestamp}] LOG_FILE: $LOG_FILE"
    echo "[${timestamp}] Domains: ${domains_with_ports[@]}"

    ensure_directory_exists "$TMP_DIR"

    local start_time=$(date "+%s")
    synchronized_log "================================================================"
    synchronized_log "🚀 SSL 인증서 검증 시작"
    synchronized_log "⏰ 시작 시간: $timestamp"
    synchronized_log "================================================================"

    tasks=()
    for domain_with_port in "${domains_with_ports[@]}"; do
        read domain port <<< "$(parse_domain_with_port "$domain_with_port")"
        tasks+=("verify_domain $domain $port")
    done

    run_in_parallel "$MAX_PARALLEL" "${tasks[@]}"

    local end_time=$(date "+%s")
    synchronized_log "⌛ 총 처리 시간: $(calculate_time "$start_time" "$end_time")"

#    process_temp_files "$TMP_DIR" "task_*.log" "delete"
}

main
