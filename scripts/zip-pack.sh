#!/bin/bash
# zip 压缩 / 解压工具
#
# 压缩:
#   bash zip-pack.sh pack ./dist
#   bash zip-pack.sh pack ./dist -o /tmp/app.zip -l 9
#   bash zip-pack.sh pack ./src -x "*.pyc" -x ".git/*" -p "secret"
#
# 解压:
#   bash zip-pack.sh unpack app.zip
#   bash zip-pack.sh unpack app.zip -d /tmp/out
#
# 查看 / 校验:
#   bash zip-pack.sh list app.zip
#   bash zip-pack.sh test app.zip

set -euo pipefail

LEVEL=6
OUTPUT=""
DEST="."
PASSWORD=""
EXCLUDES=()
JUNK_PATHS=0
QUIET=0
OVERWRITE=0

usage() {
  cat <<'EOF'
用法:
  bash zip-pack.sh pack   <路径...> [选项]
  bash zip-pack.sh unpack <zip文件> [选项]
  bash zip-pack.sh list   <zip文件>
  bash zip-pack.sh test   <zip文件>

pack 选项:
  -o, --output <文件>     输出 zip 路径（默认: <首个路径名>.zip）
  -l, --level <0-9>       压缩级别，0=仅存储，9=最高压缩（默认 6）
  -x, --exclude <模式>    排除模式，可多次指定（传给 zip -x）
  -j, --junk-paths        不保留目录结构（zip -j）
  -p, --password <密码>   ZIP 传统加密（兼容性好，安全性一般）
  -q, --quiet             安静模式
  -f, --force             覆盖已存在的 zip

unpack 选项:
  -d, --dest <目录>       解压到指定目录（默认当前目录）
  -p, --password <密码>   解压密码
  -o, --overwrite         覆盖已存在文件（unzip -o）
  -q, --quiet             安静模式

示例:
  # 打包目录
  bash zip-pack.sh pack ./release

  # 高压缩 + 排除 + 指定输出
  bash zip-pack.sh pack ./app -o /tmp/app-release.zip -l 9 \
    -x "*.log" -x ".git/*" -x "node_modules/*"

  # 加密打包
  bash zip-pack.sh pack ./conf -o conf.zip -p "MyPass123"

  # 解压到目录
  bash zip-pack.sh unpack app.zip -d /tmp/out

  # 查看 / 校验
  bash zip-pack.sh list app.zip
  bash zip-pack.sh test app.zip
EOF
}

log() { [[ "$QUIET" -eq 1 ]] || printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "未找到命令: $1（请先安装 zip/unzip）"
}

default_output_name() {
  local first="$1"
  local base
  base="$(basename "${first%/}")"
  [[ -n "$base" && "$base" != "." && "$base" != "/" ]] || base="archive"
  printf '%s.zip' "$base"
}

human_size() {
  local bytes="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec --suffix=B "$bytes"
  else
    printf '%sB' "$bytes"
  fi
}

cmd_pack() {
  require_cmd zip
  local inputs=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -o|--output) OUTPUT="${2:-}"; shift 2 ;;
      -l|--level)
        LEVEL="${2:-}"
        [[ "$LEVEL" =~ ^[0-9]$ ]] || die "压缩级别须为 0-9"
        shift 2
        ;;
      -x|--exclude) EXCLUDES+=("${2:-}"); shift 2 ;;
      -j|--junk-paths) JUNK_PATHS=1; shift ;;
      -p|--password) PASSWORD="${2:-}"; shift 2 ;;
      -q|--quiet) QUIET=1; shift ;;
      -f|--force) OVERWRITE=1; shift ;;
      -h|--help) usage; exit 0 ;;
      --) shift; inputs+=("$@"); break ;;
      -*) die "未知选项: $1" ;;
      *) inputs+=("$1"); shift ;;
    esac
  done

  [[ ${#inputs[@]} -gt 0 ]] || die "请指定要压缩的路径"
  for p in "${inputs[@]}"; do
    [[ -e "$p" ]] || die "路径不存在: $p"
  done

  if [[ -z "$OUTPUT" ]]; then
    OUTPUT="$(default_output_name "${inputs[0]}")"
  fi

  if [[ -e "$OUTPUT" ]]; then
    if [[ "$OVERWRITE" -eq 1 ]]; then
      rm -f "$OUTPUT"
    else
      die "目标已存在: $OUTPUT（使用 -f 覆盖）"
    fi
  fi

  local out_dir
  out_dir="$(dirname "$OUTPUT")"
  mkdir -p "$out_dir"

  local -a zip_args=(-r "-${LEVEL}")
  [[ "$QUIET" -eq 1 ]] && zip_args+=(-q)
  [[ "$JUNK_PATHS" -eq 1 ]] && zip_args+=(-j)
  if [[ -n "$PASSWORD" ]]; then
    zip_args+=(-P "$PASSWORD")
    warn "使用 ZIP 传统加密（-P），适合临时分发；敏感数据请改用 gpg/7z AES"
  fi

  log "压缩级别: $LEVEL"
  log "输出文件: $OUTPUT"
  log "输入路径: ${inputs[*]}"
  if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    log "排除模式: ${EXCLUDES[*]}"
  fi

  if [[ ${#EXCLUDES[@]} -gt 0 ]]; then
    zip "${zip_args[@]}" "$OUTPUT" "${inputs[@]}" -x "${EXCLUDES[@]}"
  else
    zip "${zip_args[@]}" "$OUTPUT" "${inputs[@]}"
  fi

  local size
  size="$(wc -c <"$OUTPUT" | tr -d ' ')"
  log "完成: $OUTPUT ($(human_size "$size"))"
  if command -v unzip >/dev/null 2>&1; then
    unzip -t "$OUTPUT" >/dev/null
    log "完整性校验通过"
  fi
}

cmd_unpack() {
  require_cmd unzip
  local zipfile=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -d|--dest) DEST="${2:-}"; shift 2 ;;
      -p|--password) PASSWORD="${2:-}"; shift 2 ;;
      -o|--overwrite) OVERWRITE=1; shift ;;
      -q|--quiet) QUIET=1; shift ;;
      -h|--help) usage; exit 0 ;;
      -*) die "未知选项: $1" ;;
      *)
        [[ -z "$zipfile" ]] || die "只能指定一个 zip 文件"
        zipfile="$1"
        shift
        ;;
    esac
  done

  [[ -n "$zipfile" ]] || die "请指定 zip 文件"
  [[ -f "$zipfile" ]] || die "文件不存在: $zipfile"

  mkdir -p "$DEST"
  local -a unzip_args=()
  [[ "$OVERWRITE" -eq 1 ]] && unzip_args+=(-o) || unzip_args+=(-n)
  [[ "$QUIET" -eq 1 ]] && unzip_args+=(-q)
  [[ -n "$PASSWORD" ]] && unzip_args+=(-P "$PASSWORD")

  log "解压: $zipfile -> $DEST"
  unzip "${unzip_args[@]}" "$zipfile" -d "$DEST"
  log "完成"
}

cmd_list() {
  require_cmd unzip
  local zipfile="${1:-}"
  [[ -n "$zipfile" ]] || die "请指定 zip 文件"
  [[ -f "$zipfile" ]] || die "文件不存在: $zipfile"
  unzip -l "$zipfile"
}

cmd_test() {
  require_cmd unzip
  local zipfile="${1:-}"
  [[ -n "$zipfile" ]] || die "请指定 zip 文件"
  [[ -f "$zipfile" ]] || die "文件不存在: $zipfile"
  unzip -t "$zipfile"
}

main() {
  local action="${1:-}"
  [[ -n "$action" ]] || { usage; exit 1; }
  shift || true

  case "$action" in
    pack|compress|zip) cmd_pack "$@" ;;
    unpack|extract|unzip) cmd_unpack "$@" ;;
    list|ls) cmd_list "$@" ;;
    test|check) cmd_test "$@" ;;
    -h|--help|help) usage ;;
    *) die "未知子命令: $action（见 --help）" ;;
  esac
}

main "$@"
