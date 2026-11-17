[# M302A（S905L3B）OpenWrt 固件编译资料

> 目标盒子：**魔百和 M302A / S905L3B**，非高安版本。
> 本目录是一套可直接推到 GitHub 仓库、用 Actions 一键编译的完整资料。

---

## 一、核心原理：为什么不能直接编 amlogic target

标准 OpenWrt / ImmortalWrt 源码（24.10、25.12、main）的 `target/linux` 下**都不带 amlogic（晶晨）目标**。晶晨盒子固件走 **两段式**：

1. **编通用 rootfs**：用标准 buildroot 编一个 `armsr/armv8` 通用 ARM64 根文件系统（`*-generic-rootfs.tar.gz`），里面不含任何板级适配。
2. **打包成盒子固件**：由打包脚本按 `BOARD=s905l3b` 注入第三方内核、u-boot、设备树（dtb），分区组装成可刷写的 `.img.gz`。

所以：
- `.config` 里目标必须是 `armsr/armv8/generic`，**不要写** `amlogic/meson-gxl`；
- 板级的 dtb / u-boot / 内核由打包阶段自动下载，不需要你在仓库里维护源码 dts。

---

## 二、M302A 官方参数（取自 ophub 设备数据库）

| 项目 | 值 |
|------|----|
| 型号 MODEL | M302A, M304A, CM201-1, CM211-1, CM311-1 |
| SoC | `s905l3b` |
| 打包 BOARD | **`s905l3b`** |
| 设备树 dtb | `meson-gxl-s905l3b-m302a.dtb` |
| u-boot | `u-boot-s905x-s912.bin` |
| 平台 / 家族 | amlogic / meson-gxl |
| 内核标签 | `stable` / `6.18.y` |
| 内存 / 网口 | 2GB DDR3（常见）、100Mb 百兆网口 |
| 启动方式 | TF/SD/USB 启动；非高安版可写入 eMMC |

> 对照：B860AV2.1 用 `meson-gxl-s905l3b-m302a-v2.dtb`，BOARD `s905l3b-m302a`；
> B860AV-2.1M（IP103H 系）BOARD `s905l3b-ip103h`，官方未列入自动打包。**三者 dtb/uboot 不通用**。

---

## 三、编译所需全部资料清单

### 1. 源码与资源仓库（Actions 自动拉取，无需本地准备）

| 用途 | 仓库 | 分支 / 标签 |
|------|------|------------|
| rootfs 源码 | https://github.com/openwrt/openwrt | `main`（可改 `lede`/`immortalwrt` 对应分支） |
| 第三方内核 | https://github.com/ophub/kernel | tag `kernel_stable`，系列 `6.18.y` |
| u-boot | https://github.com/ophub/u-boot | 随内核包配套 |
| 打包脚本 / action | https://github.com/ophub/amlogic-s9xxx-openwrt | `@main`（composite action） |
| 设备数据库 | 仓库内 `model_database.conf`（board/dtb/uboot 映射） | — |

### 2. 本目录提供的文件

```
m302a-openwrt-build/
├── README.md                          # 本说明（资料清单 + 参数 + 步骤）
├── config/
│   ├── config                         # armsr/armv8/generic rootfs 精简配置
│   ├── diy-part1.sh                   # feeds 更新前执行（加 feed、删包、换源）
│   └── diy-part2.sh                   # 加载 .config 后执行（改 IP/主机名/主题）
└── .github/
    └── workflows/
        └── build-m302a.yml            # Actions 两段式编译脚本
```

### 3. 运行环境依赖（workflow 的 `Initialize build environment` 步骤自动安装）

`build-essential libncurses-dev gawk flex bison git gettext libssl-dev python3 python3-pip unzip ccache rsync device-tree-compiler zlib1g-dev libelf-dev quilt subversion file`，另拉官方一键依赖清单兜底。

### 4. GitHub 仓库设置（可选）

- 上传到 Releases 需要：Settings → Secrets and variables → Actions → 新增 `GITHUB_TOKEN`（权限 `public_repo`），并开启 Settings → Actions → General → Workflow permissions 读写。
- 本目录 workflow 先上传到 **Artifacts**，不强制写 Releases；不配 token 也能在 Actions 页面下载固件。

---

## 四、使用步骤

1. 新建公开 GitHub 仓库（不勾选 README / .gitignore / License）。
2. 把本目录全部文件按结构推到仓库根目录。
3. Actions → 选 **Build M302A (S905L3B) OpenWrt** → **Run workflow**。
   - 可在弹窗里改：`openwrt_board`（默认 `s905l3b`）、`openwrt_kernel`（默认 `6.18.y`）、`openwrt_ip`、`openwrt_size`、`builder_name`。
4. 编译分两段：
   - 先出 `armsr-rootfs`（通用 rootfs.tar.gz）；
   - 再打包出 `M302A-S905L3B-Firmware`（`.img.gz`）。
5. 在任务页 Artifacts 下载固件，解压得到 `.img.gz`，用 Rufus/balenaEtcher 写入 U 盘。

### 启动与写入 eMMC

- 短接靠近网口的 USB 针脚 → 插 U 盘上电 → 从 U 盘启动。
- 浏览器访问 `192.168.1.1`，TTYD 终端执行写入 eMMC 命令（打包体系提供 `openwrt-install-to-emmc` 类脚本，以固件内实际命令为准）。

---

## 五、常见坑与核对点

1. **找不到固件 img**：检查 `.config` 目标是不是 `armsr/armv8/generic`；若写成 `amlogic/meson-gxl`，标准源码无此 target，`defconfig` 后设备选项会被清掉，`bin/targets` 下不会有镜像。
2. **网口中断不要照抄 N1**：N1 是 `&gpio_intc` 中断；S905L3B MAC 挂 GIC，打包体系已在第三方内核/dtb 里适配，不要自行改中断号。
3. **百兆 RMII**：M302A 网口为百兆，无千兆 EEE 问题，不需要 `eee-broken-1000t`。
4. **高安版**：U 盘启动失败、卡 logo，先确认机器是非高安版；高安锁 u-boot，换第三方固件需先处理 bootloader。
5. **磁盘空间**：workflow 已建虚拟扩展盘到 `/builder`；若编译中途 OOM/磁盘不足，Runner 换更大规格或减包。
6. **换源码**：想用 ImmortalWrt rootfs，把 `SOURCE_REPO` 改 `https://github.com/immortalwrt/immortalwrt.git`，`SOURCE_BRANCH` 改其存在的分支（如 `master`）。

---

## 六、开机验证（刷入后在 OpenWrt 终端执行）

```sh
cat /proc/device-tree/model        # 应显示 M302A / S905L3B 相关型号
uname -a                           # 查看内核系列（6.18.y）
ip addr                            # 确认 eth0 拿到地址
ls /boot/dtb/amlogic/              # 核对 dtb：meson-gxl-s905l3b-m302a.dtb
```

## 七、参考来源

- ophub amlogic-s9xxx-openwrt：https://github.com/ophub/amlogic-s9xxx-openwrt
- ophub 内核：https://github.com/ophub/kernel
- 设备数据库 `model_database.conf`（M302A 行：BOARD `s905l3b`）
- OpenWrt armsr target：https://github.com/openwrt/openwrt
](https://github.com/yangjianjun1/ImmWrt-s905l3b-B60av2.1.M/actions/workflows/Build_m302a.yml/badge.svg)
