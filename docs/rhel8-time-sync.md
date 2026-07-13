# RHEL 8 时间同步（chrony）

RHEL 8 / Rocky 8 / AlmaLinux 8 推荐使用 **chrony** 做 NTP 时间同步（默认服务名为 `chronyd`）。

## 一键配置（有外网）

```bash
sudo bash scripts/rhel8-setup-chrony.sh
```

默认时区 `Asia/Shanghai`，NTP 为公网源。

---

## 无外网场景（重点）

服务器不能访问公网时，**不要**使用默认的阿里云/腾讯等公网 NTP，改为：

1. **普通节点**：同步到内网 NTP
2. **一台可访问上游或人工校时的机器**：做成内网 NTP 服务端，其余机器指向它

### 1）客户端：同步内网 NTP

```bash
sudo bash scripts/rhel8-setup-chrony.sh \
  --offline \
  --servers "10.0.0.10 10.0.0.11"
```

或使用内网域名：

```bash
sudo bash scripts/rhel8-setup-chrony.sh \
  --offline \
  --servers "ntp1.corp.local ntp2.corp.local"
```

`--offline` 会禁止写入默认公网 NTP，避免空等外网超时。

### 2）服务端：本机对内网提供 NTP

有上游（例如机房级 NTP / 堡垒机可访问的内网时间源）：

```bash
sudo bash scripts/rhel8-setup-chrony.sh \
  --as-server \
  --allow "10.0.0.0/8" \
  --servers "10.1.1.1"
```

完全隔离、没有上游时，用本地时钟作为参考（精度依赖本机 RTC，需定期人工校准）：

```bash
sudo bash scripts/rhel8-setup-chrony.sh \
  --as-server \
  --allow "10.0.0.0/8" \
  --local-stratum 10
```

脚本在 `--as-server` 时会尝试通过 firewalld 放行 NTP（UDP 123）。

### 3）无外网时如何安装 chrony 包

若本机还没有 `chrony`，且没有互联网 yum 源：

```bash
# 方式 A：配置内网 yum/dnf 镜像后安装
sudo dnf install -y chrony

# 方式 B：从有外网机器下载 RPM 拷贝进来离线安装
# （版本号按实际系统替换）
sudo rpm -ivh chrony-*.rpm
```

然后再跑本脚本。

### 4）连通性检查

NTP 使用 **UDP 123**。客户端到服务端需互通：

```bash
# 在客户端测试（有 nc 时）
nc -u -vz 10.0.0.10 123

# 或看 chrony 能否拿到源
chronyc sources -v
```

若 sources 长期没有 `*`/`+`，优先排查：地址写错、防火墙、安全组、中间设备丢弃 UDP 123。

---

## 手动配置（无外网客户端示例）

```bash
sudo dnf install -y chrony   # 或离线 rpm
sudo cp -a /etc/chrony.conf /etc/chrony.conf.bak

sudo tee /etc/chrony.conf >/dev/null <<'EOF'
server 10.0.0.10 iburst
server 10.0.0.11 iburst
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

sudo timedatectl set-timezone Asia/Shanghai
sudo timedatectl set-ntp true
sudo systemctl enable --now chronyd
sudo systemctl restart chronyd
```

## 手动配置（无外网 NTP 服务端示例）

```bash
sudo tee /etc/chrony.conf >/dev/null <<'EOF'
# 有上游则写 server；没有上游则用 local
# server 10.1.1.1 iburst
local stratum 10
allow 10.0.0.0/8
driftfile /var/lib/chrony/drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony
EOF

sudo firewall-cmd --permanent --add-service=ntp
sudo firewall-cmd --reload
sudo systemctl enable --now chronyd
```

其余机器的 `/etc/chrony.conf` 指向这台服务端 IP 即可。

## 验证

```bash
timedatectl status
chronyc tracking
chronyc sources -v
# 若是 NTP 服务端，还可看谁在同步自己：
chronyc clients
```

关注点：

- `System clock synchronized: yes`、`NTP service: active`
- `chronyc sources -v` 有 `*` 当前源（仅 local 时也可能显示本地参考）
- 服务端 `allow` 网段必须覆盖客户端地址

强制步进（偏差过大时，慎用）：

```bash
sudo chronyc makestep
```

## 常用维护

```bash
systemctl status chronyd
sudo systemctl restart chronyd
chronyc sourcestats -v
```

## 注意事项

1. 无外网时务必指定内网 NTP，不要依赖公网域名解析与连通性。
2. 用 `local stratum` 的服务端没有外部真源，时钟会漂移；有条件时应有一台能校时的上游。
3. 虚拟机若启用了宿主机时间同步，可能与 chrony 冲突，保留一种即可。
4. 原配置备份为 `/etc/chrony.conf.bak.<时间戳>`。
