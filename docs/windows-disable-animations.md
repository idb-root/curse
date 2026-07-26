# Windows 关闭程序窗口动画

关闭 Windows 10 / 11 下程序窗口的打开、关闭、最小化、最大化动画，让窗口即时出现/消失，界面跟手感更强。

配套脚本：`scripts/windows-disable-animations.ps1`。

---

## 快速使用（推荐）

在 **PowerShell** 中执行（当前用户生效，无需管理员）：

```powershell
# 关闭窗口动画（默认）
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1

# 显式关闭
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 disable

# 查看当前状态
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 status

# 恢复动画
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 enable

# 修改后立即重启资源管理器使设置生效
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 disable -RestartExplorer
```

脚本会：

1. 将注册表 `MinAnimate` 设为 `0`（关闭窗口动画）
2. 调整 `UserPreferencesMask` 中与窗口动画相关的位
3. 关闭「动画效果」用户偏好（Win11 设置中的开关）

---

## 图形界面关闭

### 方式 A：辅助功能（Win10 / Win11）

1. `Win + I` 打开 **设置**
2. 进入 **辅助功能** → **视觉效果**
3. 关闭 **动画效果**

### 方式 B：性能选项（精准控制窗口动画）

1. `Win + R`，输入 `sysdm.cpl` 回车
2. **高级** → **性能** → **设置**
3. 取消勾选：**在最大化和最小化时显示窗口动画**
4. （可选）再取消：菜单淡入淡出、工具提示动画、任务栏动画等
5. 应用 → 确定

---

## 注册表手动操作

路径：

```text
HKEY_CURRENT_USER\Control Panel\Desktop\WindowMetrics
```

| 名称 | 类型 | 关闭动画 | 开启动画 |
|------|------|----------|----------|
| `MinAnimate` | 字符串 (REG_SZ) | `0` | `1` |

PowerShell 一行命令：

```powershell
# 关闭
New-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' `
  -Name MinAnimate -PropertyType String -Value '0' -Force

# 开启
New-ItemProperty -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' `
  -Name MinAnimate -PropertyType String -Value '1' -Force
```

修改后若未立即生效：注销重新登录，或重启 `explorer.exe`。

---

## 组策略（专业版 / 企业版）

1. `Win + R` → `gpedit.msc`
2. **用户配置** → **管理模板** → **控制面板** → **个性化**
3. 找到 **禁用窗口动画** → 设为 **已启用**

适合批量机器统一下发。

---

## 生效与回滚

| 操作 | 命令 / 做法 |
|------|-------------|
| 关闭动画 | 脚本 `disable`，或 GUI / 注册表如上 |
| 查看状态 | 脚本 `status` |
| 恢复动画 | 脚本 `enable`，或把 `MinAnimate` 改回 `1` |
| 立即刷新 | 脚本加 `-RestartExplorer`，或注销 |

脚本只改 **当前用户**（`HKCU`），不影响其他账户。

---

## 常见问题

| 现象 | 处理 |
|------|------|
| 执行策略禁止脚本 | 使用 `-ExecutionPolicy Bypass -File ...`，或 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| 改完仍有动画 | 加 `-RestartExplorer`，或注销；确认性能选项里窗口动画已取消 |
| 只想关窗口动画、保留其它特效 | 用「方式 B」只取消「最大化和最小化时显示窗口动画」 |
| 域控策略又被打开 | 检查组策略 / 配置管理是否覆盖 `MinAnimate` 或视觉效果 |

---

## 脚本子命令摘要

```text
disable | off     关闭程序窗口动画（默认）
enable  | on      恢复动画
status            查看 MinAnimate / AnimationEffects 状态

可选参数:
  -RestartExplorer   修改后重启资源管理器
```
