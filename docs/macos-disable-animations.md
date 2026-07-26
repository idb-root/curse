# macOS 关闭程序窗口动画

关闭 macOS 下程序窗口的打开、关闭、缩放等动画，让窗口更接近即时出现/消失。

配套脚本：`scripts/macos-disable-animations.sh`。

适用于 macOS Ventura / Sonoma / Sequoia（一般也适用于较新的 Big Sur / Monterey）。

---

## 快速使用（推荐）

在 **终端** 中执行（当前用户生效，无需管理员）：

```bash
# 赋予执行权限（首次）
chmod +x ./scripts/macos-disable-animations.sh

# 关闭窗口动画（默认）
./scripts/macos-disable-animations.sh

# 显式关闭
./scripts/macos-disable-animations.sh disable

# 查看当前状态
./scripts/macos-disable-animations.sh status

# 恢复动画
./scripts/macos-disable-animations.sh enable

# 修改后立即重启 Dock 使部分设置生效
./scripts/macos-disable-animations.sh disable --restart-dock
```

脚本会：

1. 将 `NSAutomaticWindowAnimationsEnabled` 设为 `false`（关闭窗口打开/关闭动画）
2. 将 `NSWindowResizeTime` 压到极短（接近瞬时缩放）
3. 开启辅助功能「减弱动态效果」（`reduceMotion=true`）
4. 关闭 Dock 打开应用动画，并缩短暴露动画

---

## 图形界面关闭

### 方式 A：减弱动态效果（推荐，系统级）

1. 打开 **系统设置**（System Settings）
2. 进入 **辅助功能** → **显示**
3. 打开 **减弱动态效果**（Reduce motion）

效果：大幅削弱窗口开合、桌面切换、部分 UI 过渡动画。

### 方式 B：仅降低动画观感（不彻底关闭）

1. **系统设置** → **辅助功能** → **显示**
2. 可同时打开 **减弱透明度**（可选，减轻透明层叠观感）

说明：macOS 没有像 Windows「性能选项」那样单独勾选「窗口动画」的官方开关；程序窗口开合主要靠「减弱动态效果」+ `defaults`。

---

## defaults 手动操作

```bash
# 关闭窗口打开/关闭动画
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false

# 窗口缩放接近瞬时
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# 减弱动态效果
defaults write com.apple.universalaccess reduceMotion -bool true

# Dock：关闭打开动画
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock expose-animation-duration -float 0.01

# 使 Dock 相关设置生效
killall Dock
```

恢复默认：

```bash
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool true
defaults delete NSGlobalDomain NSWindowResizeTime
defaults write com.apple.universalaccess reduceMotion -bool false
defaults write com.apple.dock launchanim -bool true
defaults delete com.apple.dock expose-animation-duration
killall Dock
```

---

## 生效与回滚

| 操作 | 命令 / 做法 |
|------|-------------|
| 关闭动画 | 脚本 `disable`，或 GUI「减弱动态效果」/ defaults 如上 |
| 查看状态 | 脚本 `status` |
| 恢复动画 | 脚本 `enable`，或关闭「减弱动态效果」并恢复 defaults |
| 立即刷新 | 脚本加 `--restart-dock`，或注销重新登录 |

脚本只改 **当前用户** 的 `defaults`，不影响其他账户。

部分 App（尤其 Electron / 自绘窗口）仍可能自带过渡动画，系统级设置无法完全覆盖。

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 改完仍有动画 | 加 `--restart-dock`；仍无效则注销或重启 |
| 只想关窗口动画、保留其它动效 | 只用 `NSAutomaticWindowAnimationsEnabled=false`，不要开 `reduceMotion`（需自行改脚本或手动 defaults） |
| 公司 MDM 又改回去 | 检查配置描述文件 / 管理策略是否强制辅助功能或偏好设置 |
| `Permission denied` | `chmod +x scripts/macos-disable-animations.sh` |

---

## 脚本子命令摘要

```text
disable | off     关闭程序窗口动画（默认）
enable  | on      恢复动画
status            查看 defaults 状态

可选参数:
  --restart-dock, -r   修改后重启 Dock
```
