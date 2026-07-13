# RHEL 8 时间同步（chrony）

RHEL 8 / Rocky 8 / AlmaLinux 8 推荐使用 **chrony** 做 NTP 时间同步（默认服务名为 `chronyd`）。

## 一键配置

在目标机器上以 root 执行：

```bash
sudo bash scripts/rhel8-setup-chrony.sh
```

默认：

- 时区：`Asia/Shanghai`
- NTP：`ntp.aliyun.com`、`ntp.tencent.com`、`time.windows.com`

自定义示例：

```bash
# 只改时区
sudo bash scripts/rhel8-setup-chrony.sh --timezone Asia/Shanghai

# 自定义 NTP 服务器
sudo bash scripts/rhel8-setup-chrony.sh --servers "ntp.aliyun.com ntp.ntsc.ac.cn"

# 同时指定
sudo bash scripts/rhel8-setup-chrony.sh \
  --timezone Asia/Shanghai \
  --servers "ntp.aliyun.com ntp.tencent.com"
```

脚本会：安装 chrony → 备份并重写 `/etc/chrony.conf` → 设置时区 → 启用 NTP → 启动 `chronyd` → 输出同步状态。

## 手动步骤（等价操作）

```bash
# 1. 安装
sudo dnf install -y chrony

# 2. 编辑配置（示例）
sudo cp -a /etc/chrony.conf /etc/chrony.conf.bak
sudo tee /etc/chrony.conf >/dev/null <<'EOF'
server ntp.aliyun.com iburst
server ntp.tencent.com iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

# 3. 时区与 NTP
sudo timedatectl set-timezone Asia/Shanghai
sudo timedatectl set-ntp true

# 4. 启动服务
sudo systemctl enable --now chronyd
sudo systemctl restart chronyd
```

## 验证

```bash
timedatectl status
chronyc tracking
chronyc sources -v
```

关注点：

- `timedatectl` 中 `System clock synchronized: yes`、`NTP service: active`
- `chronyc sources -v` 中有一行以 `*` 开头，表示当前选用的同步源
- `chronyc tracking` 中 `Leap status` 一般为 `Normal`

若刚启动尚未同步成功，等待几秒后再查；偏差过大时可强制步进（慎用）：

```bash
sudo chronyc makestep
```

## 常用维护命令

```bash
# 查看服务
systemctl status chronyd

# 重载配置
sudo systemctl restart chronyd

# 临时指定服务器（重启后失效，持久化请改 /etc/chrony.conf）
sudo chronyc add server ntp.aliyun.com iburst

# 查看偏移与抖动
chronyc sourcestats -v
```

## 防火墙（若本机作为 NTP 服务端）

仅当本机要对内网提供 NTP 时需要放行 UDP 123：

```bash
sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
```

作为客户端同步公网/内网 NTP 时，一般**不需要**额外开放入站端口。

## 注意事项

1. 虚拟机若开了主机时间同步（VMware Tools / VirtualBox Guest Additions / cloud-init），可能与 chrony 冲突；优先保留一种机制。
2. 生产环境建议改用内网 NTP 或可靠的公共池，避免依赖单一外网源。
3. 原配置会备份为 `/etc/chrony.conf.bak.<时间戳>`。
