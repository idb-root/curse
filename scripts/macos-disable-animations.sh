#!/usr/bin/env bash
# 关闭 / 恢复 macOS 程序窗口动画（打开、关闭、缩放等）。
# 用法:
#   ./macos-disable-animations.sh
#   ./macos-disable-animations.sh disable
#   ./macos-disable-animations.sh enable
#   ./macos-disable-animations.sh status
#   ./macos-disable-animations.sh disable --restart-dock

set -euo pipefail

ACTION="${1:-disable}"
RESTART_DOCK=0

for arg in "${@:2}"; do
  case "$arg" in
    --restart-dock|-r)
      RESTART_DOCK=1
      ;;
    *)
      echo "[WARN] 忽略未知参数: $arg" >&2
      ;;
  esac
done

info() { echo "[INFO] $*"; }
warn() { echo "[WARN] $*" >&2; }

read_bool_default() {
  # 读取 defaults 布尔值；未设置时输出 "unset"
  local domain="$1"
  local key="$2"
  local value
  if value="$(defaults read "$domain" "$key" 2>/dev/null)"; then
    case "$value" in
      1|true|YES|yes) echo "true" ;;
      0|false|NO|no) echo "false" ;;
      *) echo "$value" ;;
    esac
  else
    echo "unset"
  fi
}

read_float_default() {
  local domain="$1"
  local key="$2"
  if defaults read "$domain" "$key" &>/dev/null; then
    defaults read "$domain" "$key"
  else
    echo "unset"
  fi
}

show_status() {
  local win_anim reduce_motion resize_time launch_anim
  win_anim="$(read_bool_default NSGlobalDomain NSAutomaticWindowAnimationsEnabled)"
  reduce_motion="$(read_bool_default com.apple.universalaccess reduceMotion)"
  resize_time="$(read_float_default NSGlobalDomain NSWindowResizeTime)"
  launch_anim="$(read_bool_default com.apple.dock launchanim)"

  echo '=== macOS 程序窗口动画状态 ==='
  echo "NSAutomaticWindowAnimationsEnabled : ${win_anim}"
  echo "reduceMotion                       : ${reduce_motion}"
  echo "NSWindowResizeTime                 : ${resize_time}"
  echo "Dock launchanim                    : ${launch_anim}"
  echo ''
  echo '说明: NSAutomaticWindowAnimationsEnabled=false 且 reduceMotion=true 时，窗口打开/关闭动画最弱。'
}

disable_animations() {
  # 关闭系统级窗口打开/关闭动画
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
  # 将窗口缩放时间压到极短，接近瞬时
  defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
  # 辅助功能「减弱动态效果」
  defaults write com.apple.universalaccess reduceMotion -bool true
  # Dock：关闭打开应用动画、缩短暴露动画
  defaults write com.apple.dock launchanim -bool false
  defaults write com.apple.dock expose-animation-duration -float 0.01
  defaults write com.apple.dock mineffect -string scale

  info '已关闭程序窗口动画（NSAutomaticWindowAnimationsEnabled=false，reduceMotion=true）'
}

enable_animations() {
  defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool true
  defaults delete NSGlobalDomain NSWindowResizeTime 2>/dev/null || true
  defaults write com.apple.universalaccess reduceMotion -bool false
  defaults write com.apple.dock launchanim -bool true
  defaults delete com.apple.dock expose-animation-duration 2>/dev/null || true
  defaults delete com.apple.dock mineffect 2>/dev/null || true

  info '已恢复程序窗口动画（系统默认偏好）'
}

restart_dock() {
  warn '正在重启 Dock …'
  killall Dock 2>/dev/null || true
  info 'Dock 已重启'
}

case "$(printf '%s' "$ACTION" | tr '[:upper:]' '[:lower:]')" in
  disable|off)
    disable_animations
    ;;
  enable|on)
    enable_animations
    ;;
  status)
    show_status
    exit 0
    ;;
  -h|--help|help)
    cat <<'EOF'
用法: macos-disable-animations.sh [disable|enable|status] [--restart-dock]

  disable | off     关闭程序窗口动画（默认）
  enable  | on      恢复动画
  status            查看当前 defaults 状态

可选参数:
  --restart-dock, -r   修改后重启 Dock 使部分设置立即生效
EOF
    exit 0
    ;;
  *)
    echo "[ERROR] 未知子命令: $ACTION（可用: disable / enable / status）" >&2
    exit 1
    ;;
esac

show_status

if [[ "$RESTART_DOCK" -eq 1 ]]; then
  restart_dock
else
  info '若界面仍有动画，可注销重新登录，或加 --restart-dock 重启 Dock'
fi
