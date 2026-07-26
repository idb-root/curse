# curse

运维脚本与说明集合。

## Windows 关闭程序窗口动画

关闭 Windows 10/11 程序打开、关闭、最小化/最大化动画：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 status
powershell -ExecutionPolicy Bypass -File .\scripts\windows-disable-animations.ps1 enable
```

详细说明见 [docs/windows-disable-animations.md](docs/windows-disable-animations.md)。

## macOS 关闭程序窗口动画

关闭 macOS 程序打开、关闭、缩放等窗口动画：

```bash
chmod +x ./scripts/macos-disable-animations.sh
./scripts/macos-disable-animations.sh
./scripts/macos-disable-animations.sh status
./scripts/macos-disable-animations.sh enable
```

详细说明见 [docs/macos-disable-animations.md](docs/macos-disable-animations.md)。
