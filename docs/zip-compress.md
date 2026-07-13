# Zip 压缩与解压

运维常用的 ZIP 打包 / 解压说明，配套脚本：`scripts/zip-pack.sh`。

依赖：`zip`、`unzip`（RHEL/CentOS: `yum install -y zip unzip`；Debian/Ubuntu: `apt install -y zip unzip`）。

---

## 快速使用

```bash
# 打包目录（生成 release.zip）
bash scripts/zip-pack.sh pack ./release

# 高压缩 + 排除无用文件 + 指定输出
bash scripts/zip-pack.sh pack ./app -o /tmp/app-release.zip -l 9 \
  -x "*.log" -x ".git/*" -x "node_modules/*" -x "__pycache__/*"

# 加密打包（传统 ZIP 密码，兼容 Windows）
bash scripts/zip-pack.sh pack ./conf -o conf.zip -p "MyPass123" -f

# 解压
bash scripts/zip-pack.sh unpack app.zip -d /tmp/out

# 查看内容 / 校验完整性
bash scripts/zip-pack.sh list app.zip
bash scripts/zip-pack.sh test app.zip
```

---

## 原生命令速查

不依赖脚本时，直接用系统命令：

### 压缩

```bash
# 递归打包目录
zip -r archive.zip ./dir

# 压缩级别 0(仅存储) ~ 9(最高)
zip -r -9 archive.zip ./dir

# 排除模式
zip -r archive.zip ./dir -x "*.git*" -x "*node_modules*"

# 不保留路径（所有文件铺平）
zip -j archive.zip ./dir/*

# 加密（会提示输入密码；脚本用 -P 非交互）
zip -re archive.zip ./dir
```

### 解压

```bash
unzip archive.zip                 # 解到当前目录
unzip archive.zip -d /tmp/out     # 解到指定目录
unzip -l archive.zip              # 只看列表
unzip -t archive.zip              # 校验
unzip -o archive.zip              # 覆盖已存在文件
unzip -n archive.zip              # 不覆盖
```

### 查看占用

```bash
ls -lh archive.zip
unzip -l archive.zip | tail -1
```

---

## 压缩级别怎么选

| 级别 | 场景 |
|------|------|
| `-0` | 已压缩内容（jpg/mp4/jar），几乎不再缩小，求速度 |
| `-1` ~ `-3` | 临时备份、网络差时优先完成 |
| `-6`（默认） | 一般发布包 |
| `-9` | 体积敏感的分发包、跨机房传输 |

体积收益通常在中等文本/代码上更明显；对已经压缩的二进制提升有限。

---

## 中文文件名注意

Linux 下 `zip`/`unzip` 默认按 UTF-8 处理；Windows 资源管理器解压时可能乱码。

可选处理：

```bash
# 解压时尝试用 GBK 解释名称（需 unzip 支持，或改用 7z）
unzip -O GBK archive.zip -d /tmp/out

# 更稳妥：用 7-Zip（跨平台 UTF-8 兼容更好）
7z a archive.zip ./dir
7z x archive.zip -o/tmp/out
```

跨系统分发优先约定「包内路径只用 ASCII」，或统一用 `7z`。

---

## 加密说明

- `zip -P` / 脚本 `-p`：ZIP 传统加密，**兼容性好、安全性一般**，适合临时配置包，不适合长期保管密钥/证书。
- 敏感数据建议：

```bash
# gpg 对称加密
tar czf - ./dir | gpg -c -o dir.tar.gz.gpg

# 或 7z AES-256
7z a -t7z -mhe=on -p'YourStrongPass' archive.7z ./dir
```

---

## 大文件与分卷

ZIP 原生分卷较少用在 Linux 运维；大包更常见：

```bash
# 先打 zip，再按体积切开（接收方需 cat 拼回）
zip -r -9 big.zip ./data
split -b 500M -d big.zip big.zip.part.

# 合并
cat big.zip.part.* > big.zip
unzip -t big.zip
```

或直接用 `7z` 分卷：`7z a -v500m archive.7z ./data`。

---

## 常见故障

| 现象 | 处理 |
|------|------|
| `command not found: zip` | 安装 `zip` / `unzip` |
| 目标 zip 已存在 | 脚本加 `-f`，或先删旧文件 |
| 解压提示已存在 | `unpack -o` 覆盖，或换空目录 `-d` |
| 密码错误 | 确认 `-p` 与打包时一致；传统加密区分大小写 |
| 中文乱码 | 见上文「中文文件名」；改用 7z |
| 压缩几乎无效果 | 内容已是压缩格式，改用 `-0` 提速即可 |

---

## 脚本选项摘要

```text
pack   -o 输出.zip  -l 0-9  -x 排除  -j 平铺  -p 密码  -f 覆盖  -q
unpack -d 目录      -p 密码  -o 覆盖  -q
list / test
```
