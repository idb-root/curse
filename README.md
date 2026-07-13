# curse

运维脚本与说明集合。

## RHEL 8 时间同步

使用 chrony 配置 RHEL 8 / Rocky 8 / AlmaLinux 8 时间同步：

```bash
# 有外网
sudo bash scripts/rhel8-setup-chrony.sh

# 无外网：同步内网 NTP
sudo bash scripts/rhel8-setup-chrony.sh --offline --servers "10.0.0.10"

# 无外网：本机作为内网 NTP 服务端
sudo bash scripts/rhel8-setup-chrony.sh --as-server --allow "10.0.0.0/8" --local-stratum 10
```

详细说明见 [docs/rhel8-time-sync.md](docs/rhel8-time-sync.md)。
