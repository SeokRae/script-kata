#!/bin/sh

# POSIX 쉘을 사용해 Mac OS, Linux, Unix 등에서 동작하도록 함

# 명령어: bash -n <파일명>
# - 스크립트의 구문을 확인합니다.
# - 실행 시 오류를 발생시킬 수 있는 문법 문제를 보고합니다.
# - 스크립트를 실제로 실행하지 않으므로 안전하게 문법을 확인할 수 있습니다.

# 명령어 2>/dev/null
# - >: 출력 리다이렉션.
#  - 파일에 기록하거나 특정 위치로 데이터를 보냄.
# - /dev/null: "블랙홀"처럼 동작하는 특별한 파일로, 여기에 데이터를 쓰면 시스템이 데이터를 무시함.
# - 숫자 지정:
#  - 1>: 표준 출력(stdout)을 리다이렉션.
#  - 2>: 표준 에러(stderr)을 리다이렉션.

# Bash 의존성 확인
check_bash_dependency() {
  if ! command -v bash >/dev/null 2>&1; then
    echo "❌ 'bash'가 시스템에 설치되지 않았습니다. 설치 후 다시 실행하세요."
    exit 1
  fi
}

# 문법 체크 함수
check_syntax() {
  local file="$1"

  if [ -f "$file" ]; then

    bash -n "$file" 2>/dev/null

    if [ $? -eq 0 ]; then
      echo "✅ [$file]: 문법 체크 통과"
    else
      echo "❌ [$file]: 문법 오류 발견"
      echo "📋 오류 상세 정보:"

      bash -n "$file" # 에러 상세 메시지 출력
      return 1
    fi
  else
    echo "❌ [$file]: 파일이 존재하지 않음"
    return 1
  fi
}

# 현재 디렉토리 및 하위 디렉토리에서 모든 .sh 파일 검색 후 문법 점검
check_files() {
  # 현 위치의 경로 가져오는 명령어
  local current_dir="$PWD"

  # 모든 .sh 파일 검색 (공백이나 특수 문자 처리 지원)
  echo "🚀 .sh 파일 검색 중..."
  # 현재 디렉토리 및 하위 디렉토리 파일 확인
  find "$current_dir" -type f -name "*.sh" | while IFS= read -r file; do
    check_syntax "$file" || overall_status=1
  done

  # 검색 결과가 없는 경우 처리
  if [ "$(find "$current_dir" -type f -name "*.sh" | wc -l)" -eq 0 ]; then
    echo "❌ .sh 파일이 발견되지 않았습니다."
    return 1
  fi
}

# 메인 실행
main() {
    # Bash 의존성 확인
    check_bash_dependency

    echo "🚀 쉘 스크립트 파일 문법 점검 시작"
    overall_status=0 # 초기 상태 코드

    check_files

    if [ "$overall_status" -eq 0 ]; then
        echo "✅ 쉘 스크립트 파일 문법 점검 완료"
    else
        echo "❌ 일부 파일에서 문법 오류가 발견되었습니다."
        exit 1
    fi
}

# 스크립트 실행
main