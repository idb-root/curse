#Requires -Version 5.1
<#
.SYNOPSIS
  关闭 / 恢复 Windows 程序窗口动画（打开、关闭、最小化、最大化）。

.DESCRIPTION
  默认关闭窗口动画（注册表 MinAnimate=0），并同步关闭「动画效果」相关用户偏好。
  适用于 Windows 10 / 11。修改后一般立即生效；若未生效可注销或重启资源管理器。

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\windows-disable-animations.ps1
  powershell -ExecutionPolicy Bypass -File .\windows-disable-animations.ps1 disable
  powershell -ExecutionPolicy Bypass -File .\windows-disable-animations.ps1 enable
  powershell -ExecutionPolicy Bypass -File .\windows-disable-animations.ps1 status
#>

[CmdletBinding()]
param(
  [Parameter(Position = 0)]
  [ValidateSet('disable', 'enable', 'status', 'off', 'on')]
  [string]$Action = 'disable',

  [switch]$RestartExplorer
)

$ErrorActionPreference = 'Stop'

$WindowMetricsPath = 'HKCU:\Control Panel\Desktop\WindowMetrics'
$DesktopPath = 'HKCU:\Control Panel\Desktop'
$AccessibilityPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Accessibility'
$VisualEffectsPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'

function Write-Info([string]$Message) {
  Write-Host "[INFO] $Message"
}

function Write-WarnMsg([string]$Message) {
  Write-Warning $Message
}

function Ensure-RegistryPath([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    New-Item -Path $Path -Force | Out-Null
  }
}

function Get-MinAnimate {
  Ensure-RegistryPath $WindowMetricsPath
  $value = (Get-ItemProperty -LiteralPath $WindowMetricsPath -Name 'MinAnimate' -ErrorAction SilentlyContinue).MinAnimate
  if ($null -eq $value) {
    return $null
  }
  return [string]$value
}

function Set-MinAnimate([string]$Value) {
  Ensure-RegistryPath $WindowMetricsPath
  New-ItemProperty -LiteralPath $WindowMetricsPath -Name 'MinAnimate' -PropertyType String -Value $Value -Force | Out-Null
}

function Set-UserPreferencesMaskBits {
  param(
    [bool]$EnableAnimations
  )

  # UserPreferencesMask 控制多项视觉效果；第 2 位（0-based index 1）与窗口动画相关。
  Ensure-RegistryPath $DesktopPath
  $current = (Get-ItemProperty -LiteralPath $DesktopPath -Name 'UserPreferencesMask' -ErrorAction SilentlyContinue).UserPreferencesMask
  if ($null -eq $current -or $current.Length -lt 1) {
    # Windows 常见默认掩码（长度 8）
    $bytes = [byte[]](0x9E, 0x3E, 0x07, 0x80, 0x12, 0x00, 0x00, 0x00)
  } else {
    $bytes = [byte[]]$current
  }

  if ($EnableAnimations) {
    $bytes[0] = $bytes[0] -bor 0x02
  } else {
    $bytes[0] = $bytes[0] -band (-bnot 0x02)
  }

  New-ItemProperty -LiteralPath $DesktopPath -Name 'UserPreferencesMask' -PropertyType Binary -Value $bytes -Force | Out-Null
}

function Set-AnimationEffectsPreference([bool]$Enabled) {
  # Windows 11「设置 → 辅助功能 → 视觉效果 → 动画效果」对应项
  Ensure-RegistryPath $AccessibilityPath
  $value = if ($Enabled) { 1 } else { 0 }
  New-ItemProperty -LiteralPath $AccessibilityPath -Name 'AnimationEffects' -PropertyType DWord -Value $value -Force | Out-Null

  # Explorer 视觉效果：3=自定义；配合 MinAnimate 更易被系统采纳
  Ensure-RegistryPath $VisualEffectsPath
  New-ItemProperty -LiteralPath $VisualEffectsPath -Name 'VisualFXSetting' -PropertyType DWord -Value 3 -Force | Out-Null
}

function Show-Status {
  $minAnimate = Get-MinAnimate
  $animEffects = (Get-ItemProperty -LiteralPath $AccessibilityPath -Name 'AnimationEffects' -ErrorAction SilentlyContinue).AnimationEffects

  Write-Host '=== Windows 程序窗口动画状态 ==='
  if ($null -eq $minAnimate) {
    Write-Host 'MinAnimate           : (未设置，系统默认通常为开启)'
  } else {
    $state = if ($minAnimate -eq '0') { '已关闭' } else { '已开启' }
    Write-Host ("MinAnimate           : {0} ({1})" -f $minAnimate, $state)
  }

  if ($null -eq $animEffects) {
    Write-Host 'AnimationEffects     : (未设置)'
  } else {
    $state = if ([int]$animEffects -eq 0) { '已关闭' } else { '已开启' }
    Write-Host ("AnimationEffects     : {0} ({1})" -f $animEffects, $state)
  }

  Write-Host ''
  Write-Host '说明: MinAnimate=0 表示关闭窗口最小化/最大化/打开关闭动画。'
}

function Invoke-RestartExplorer {
  Write-WarnMsg '正在重启资源管理器 explorer.exe …'
  Get-Process -Name explorer -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 800
  Start-Process explorer.exe
  Write-Info '资源管理器已重启'
}

function Disable-WindowAnimations {
  Set-MinAnimate '0'
  Set-UserPreferencesMaskBits -EnableAnimations:$false
  Set-AnimationEffectsPreference -Enabled:$false
  Write-Info '已关闭程序窗口动画（MinAnimate=0，动画效果关闭）'
}

function Enable-WindowAnimations {
  Set-MinAnimate '1'
  Set-UserPreferencesMaskBits -EnableAnimations:$true
  Set-AnimationEffectsPreference -Enabled:$true
  Write-Info '已恢复程序窗口动画（MinAnimate=1，动画效果开启）'
}

switch ($Action.ToLowerInvariant()) {
  { $_ -in @('disable', 'off') } { Disable-WindowAnimations }
  { $_ -in @('enable', 'on') } { Enable-WindowAnimations }
  'status' { Show-Status; return }
}

Show-Status

if ($RestartExplorer) {
  Invoke-RestartExplorer
} else {
  Write-Info '若界面仍有动画，可注销登录，或加 -RestartExplorer 重启资源管理器'
}
