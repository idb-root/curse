#!/bin/bash
# cnnc-api 进程守护：不存在则拉起
# 用法：
#   chmod +x /app/apps/cnnc-api/cnnc-api-watchdog.sh
#   # 每分钟检查一次
#   * * * * * /app/apps/cnnc-api/cnnc-api-watchdog.sh >> /app/apps/cnnc-api/watchdog.log 2>&1

set -euo pipefail

APP_DIR="/app/apps/cnnc-api"
APP_BIN="${APP_DIR}/cnnc-api"
APP_ARGS="--hertz.profiles.active=ccprod"
APP_LOG="/app/apps/cnnc-api.log"
PID_FILE="${APP_DIR}/cnnc-api.pid"
LOCK_FILE="${APP_DIR}/cnnc-api-watchdog.lock"
WATCHDOG_LOG="${APP_DIR}/watchdog.log"

export GOROOT="${GOROOT:-/usr/local/go}"
export GOPATH="${GOPATH:-${HOME}/go}"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

is_running() {
  # 精确匹配二进制 + 启动参数，避免误匹配其它 api 进程
  pgrep -f "${APP_BIN}.*${APP_ARGS}" >/dev/null 2>&1
}

start_app() {
  if [[ ! -x "${APP_BIN}" ]]; then
    log "ERROR: 二进制不存在或不可执行: ${APP_BIN}"
    return 1
  fi

  cd "${APP_DIR}"
  nohup "${APP_BIN}" ${APP_ARGS} > "${APP_LOG}" 2>&1 &
  local pid=$!
  echo "${pid}" > "${PID_FILE}"
  # 给进程一点启动时间再确认
  sleep 1
  if is_running; then
    log "STARTED pid=$(pgrep -nf "${APP_BIN}.*${APP_ARGS}") log=${APP_LOG}"
    return 0
  fi
  log "ERROR: 启动后进程仍不存在，请检查 ${APP_LOG}"
  return 1
}

mkdir -p "${APP_DIR}"

# 防止 cron 重叠执行
exec 9>"${LOCK_FILE}"
if ! flock -n 9; then
  log "SKIP: 已有 watchdog 在执行"
  exit 0
fi

if is_running; then
  pid="$(pgrep -nf "${APP_BIN}.*${APP_ARGS}" || true)"
  echo "${pid}" > "${PID_FILE}"
  log "OK: 进程存在 pid=${pid}"
  exit 0
fi

log "WARN: 进程不存在，准备启动"
start_app
