# 斐讯 N1 ImmortalWrt 精简固件编译仓库

- 目标设备：Phicomm N1（Amlogic S905D / meson-gxl）
- 源码分支：`openwrt-24.10`
- 定位：旁路由极简固件（SSH + LuCI + 基础网络 + 防火墙），无 IPv6、无 Docker、无 NAS、无拨号、无多余工具
- 编译方式：GitHub Actions（带 ccache 缓存、中科大 feeds 源、可替换自定义 DTS）

## 目录结构

```
n1-immortalwrt-build/
├── .config                          # N1 极简编译配置（仓库根目录）
├── patches/
│   ├── README.md                    # DTS 替换说明
│   └── meson-gxl-s905d-phicomm-n1.dts   # 可选：自定义 DTS（不放则用上游默认）
└── .github/
    └── workflows/
        └── build.yml               # Actions 编译脚本
```

## 使用步骤

1. 新建公开 GitHub 仓库（不要勾选 README / .gitignore / License）。
2. 把本目录全部文件上传到仓库根目录，保持上述结构。
3. 顶部菜单进入 **Actions**，左侧选择 `Build ImmortalWrt N1`。
4. 点 **Run workflow** 手动触发；首次约 40~80 分钟，后续有 ccache 会更快。
5. 编译成功后在任务页 **Artifacts** 下载 `N1-ImmortalWrt-Firmware`，解压得到 `.img.gz`。

## 可选开关（直接改 `.config`）

| 需求 | 配置项 | 改为 |
|------|--------|------|
| 开启 IPv6 | `CONFIG_IPV6=n` | `=y` |
| 开启 ksmbd 共享 | `CONFIG_PACKAGE_ksmbd-server=n` | `=y` |
| 支持 NTFS | `CONFIG_PACKAGE_kmod-fs-ntfs3=n` | `=y` |
| 支持 f2fs | `CONFIG_PACKAGE_kmod-fs-f2fs=n` | `=y` |

## 固件刷写

1. 用 Rufus 将 `.img.gz` 写入 U 盘。
2. N1 短接靠近网口的 USB 针脚，上电从 U 盘启动。
3. 进入系统后执行 `install-to-emmc` 写入 EMMC，完成后拔 U 盘重启。

## 常见坑

- `.config` 必须在仓库根目录，不能放进 `.github`。
- workflow 中不要再跑 `make menuconfig`，避免覆盖 `.config`。
- 源码由脚本自动 `git clone`，仓库内不需要提前放固件源码。
- 私有仓库 Actions 免费分钟数有限，建议公开仓库。
