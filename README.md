# curse

运维脚本与说明集合。

## Zip 压缩

打包 / 解压 / 校验：

```bash
bash scripts/zip-pack.sh pack ./release
bash scripts/zip-pack.sh pack ./app -o /tmp/app.zip -l 9 -x "*.log" -x ".git/*"
bash scripts/zip-pack.sh unpack app.zip -d /tmp/out
bash scripts/zip-pack.sh list app.zip
```

详细说明见 [docs/zip-compress.md](docs/zip-compress.md)。
