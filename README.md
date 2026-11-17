# ImmWrt-s905l3b-B60av2.1.M

> 基于 **ImmortalWrt openwrt-24.10** 自动编译固件，适配盒子：M302A / B860AV2.1-M（Amlogic S905L3B，**eMMC 闪存版本**）
> GitHub Actions 在线编译框架，不 fork 上游源码，编译时动态拉取官方源码，脚本注入硬件适配。

[![Build status](https://github.com/yangjianjun1/ImmWrt-s905l3b-B60av2.1.M/actions/workflows/Build_m302a.yml/badge.svg)](https://github.com/yangjianjun1/ImmWrt-s905l3b-B60av2.1.M/actions/workflows/Build_m302a.yml)

---

## 📌 项目简介

本仓库是一套**自动化编译脚手架**，不是完整 OpenWrt 源码仓库。

每次触发编译流程时，自动拉取上游 ImmortalWrt 官方源码，通过自定义脚本注入 S905L3B（M302A）的硬件适配信息，生成适配该机顶盒的 ImmortalWrt 固件。

- 上游源码地址：https://github.com/immortalwrt/immortalwrt
- 上游分支：`openwrt-24.10`
- 目标 SOC：Amlogic S905L3B
- 目标机型：M302A / B860AV2.1-M
- 闪存类型：**eMMC Flash（Squashfs 磁盘镜像）**
- 固件格式：`sysupgrade.img.gz`（gzip 压缩磁盘镜像）
- 内核版本：6.6

> ⚠️ 重要提醒：该固件仅适配 **eMMC 版本** M302A / B860AV2.1-M；NAND 版本盒子分区结构不同，刷入会无法启动。

---

## 📂 仓库目录与全部文件说明

```
ImmWrt-s905l3b-B60av2.1.M/
├── .github/workflows/
│   ├── Build_m302a.yml      # M302A eMMC 编译主工作流
│   └── Delete old.yml        # 清理历史产物辅助工作流（可选）
├── diy/
│   ├── dts/
│   │   └── meson-gxl-s905l3b-m302a.dts  # S905L3B eMMC 设备树
│   ├── op/
│   │   ├── isos1.sh         # 源码预处理脚本（硬件适配注入）
│   │   └── isos2.sh         # feeds 后置处理脚本（软件源、插件源）
│   ├── m302a.config         # M302A eMMC 固件编译配置
│   └── n1.config            # 备用：斐讯 N1（S905D）编译配置
└── README.md                # 项目说明文档
```

### 1. `.github/workflows/Build_m302a.yml`

✅ 整个编译流水线的主控文件，GitHub Actions 配置文件。

**触发方式**：手动运行 `workflow_dispatch`（仓库页面 Actions 里手动点启动）。

**完整执行步骤：**

1. Checkout：拉取当前仓库（本脚手架）所有文件。
2. Free disk space：清理运行机磁盘，避免空间不足编译失败。
3. Initialization environment：安装全套编译依赖（gcc、dtc 设备树编译器、lib、编译工具链等）。
4. Clone source code：`git clone --depth 1` 拉取 ImmortalWrt 上游源码到 `openwrt/` 目录。
5. 复制 `isos1.sh`、`isos2.sh` 到 openwrt 根目录，执行 `isos1.sh`。
6. feeds update & feeds install：更新并安装所有软件包源。
7. 导入编译配置：`cp ../diy/m302a.config ./.config`（先复制配置，再跑 isos2.sh）。
8. 执行 `isos2.sh`：处理软件源镜像、第三方插件源。
9. `make defconfig`：根据 .config 自动校准、补齐依赖配置项。
10. `make download -j$(nproc)`：预下载所有源码包，避免编译时下载超时。
11. `make -j$(nproc) V=s`：正式编译固件。
12. Prepare artifacts：整理固件产物。
13. Upload artifacts：上传固件、配置文件到本次运行记录，供下载。

### 2. `.github/workflows/Delete old.yml`

✅ 辅助清理脚本（可选）。

- 作用：定期删除历史 workflow 运行记录、旧的固件下载产物。
- 用途：GitHub 免费账户有存储配额，长时间累积编译包会占用空间，导致后续编译上传失败。

### 3. `diy/dts/meson-gxl-s905l3b-m302a.dts`

✅ S905L3B eMMC 设备树源文件。

> 设备树（DTS）：向 Linux 内核描述板子硬件信息的文本文件。

内容包含：

- eMMC（SD/MMC）控制器与存储分区定义。
- 网口、USB、串口、LED 指示灯、红外、供电、时钟等硬件资源。
- 内核启动时依靠该 dtb 识别板载硬件。

> 编译阶段：isos1.sh 将它复制到源码目录，内核编译时自动编译成 dtb 二进制。

> 约束：dts 内 eMMC 节点、分区必须与板子实际硬件一致；**不要沿用 NAND 的 nand 节点与 mtd 分区定义**。

### 4. `diy/op/isos1.sh`

✅ **源码预处理脚本（feeds 执行之前运行）【硬件层注入】**。

执行时机：刚拉取完 ImmortalWrt 上游源码之后。

工作内容：

1. `mkdir -p target/linux/amlogic/meson/dts`
   > ImmortalWrt 上游原生没有这个 dts 目录，之前报错 `No such file or directory` 就是缺少该目录。
2. 复制 `meson-gxl-s905l3b-m302a.dts` 到源码内 dts 目录。
3. 向 `target/linux/amlogic/meson/Makefile` 追加一段 `Device/m302a` 机型定义：
   - 机型名称、SOC 型号、绑定的 DTS 文件名。
   - eMMC 镜像参数：`IMAGE_SIZE := 256m`，输出 `sysupgrade.img.gz`（Squashfs 磁盘镜像 + gzip）。
   - **不含** UBI/NAND 参数（BLOCKSIZE、PAGESIZE、UBINIZE_OPTS、VID_HDR_OFFSET）。

> 边界规则：isos1.sh **只处理硬件、平台、内核、镜像打包规则**，不处理 Luci 插件、软件包开关。

### 5. `diy/op/isos2.sh`

✅ **Feeds 后置处理脚本（feeds install 完成、导入 .config 之后运行）【软件源处理】**。

执行时机：

`feeds update -a && feeds install -a` → 导入 m302a.config → 执行 isos2.sh。

适合做：

- 替换 feeds.conf.default 为国内镜像源，解决国外源下载慢、超时。
- 添加第三方插件 feed 源（例如 helloworld 等），追加后更新并安装 feed。

> 边界规则：
>
> - 不要在这里修改 DTS、新增机型 profile（交给 isos1.sh）。
> - 如果需要 sed 修改 .config，**必须保证顺序是先复制 .config，再执行 isos2.sh**，否则报 `sed: can't read .config: No such file or directory`。

### 6. `diy/m302a.config`

✅ M302A eMMC 专属编译配置文件（对应 OpenWrt 源码根目录的 `.config`）。

OpenWrt 编译的核心总开关，保存全部编译选项：

- CPU 架构、目标平台、文件系统。
- 内核驱动模块（例如 kmod-fs-ksmbd SMB 共享驱动）。
- Luci 界面、插件、应用程序、工具软件。
- 库、网络组件、IPv4/IPv6 等功能开关。

> 使用方式：CI 流程中将它复制为 openwrt 目录下的 `.config`，`make defconfig` 基于这份配置补齐依赖。

> 最佳实践：优先在这里勾选需要的功能，减少 isos2.sh 里 sed 操作。

### 7. `diy/n1.config`

✅ 备用配置文件：斐讯 N1（S905D）编译配置。

- 硬件和 M302A 完全不同，DTS、分区参数不一样，不可混用。
- 如需编译 N1 固件，可以新建一份 `Build_n1.yml` 工作流读取这个配置。

---

## ⏱️ CI 编译时序总流程

```
拉取 ImmortalWrt 上游源码
        ↓
执行 isos1.sh（注入 DTS + 新增 m302a 机型 + eMMC 镜像参数）
        ↓
feeds update -a && feeds install -a
        ↓
cp ../diy/m302a.config ./.config
        ↓
执行 isos2.sh（替换国内源、添加第三方插件源）
        ↓
make defconfig（校验配置，自动补齐依赖）
        ↓
make download（预下载源码包）
        ↓
make -j$(nproc) V=s（编译固件）
        ↓
收集固件，上传 Artifacts
```

---

## 📥 固件产物信息

编译成功后上游源码内输出路径：

```
openwrt/bin/targets/amlogic/meson/istoreos-amlogic-meson-m302a-squashfs-sysupgrade.img.gz
```

上传产物会重命名为：

```
istoreos-24.10-时间戳-m302a-s905l3b-emmc-squashfs-sysupgrade.img.gz
```

- 固件类型：eMMC Squashfs 磁盘镜像（gzip 压缩）。
- 刷写方式：OpenWrt 系统内网页后台 / 命令行 sysupgrade 升级；裸机可配合 Amlogic 写入工具将镜像写入 eMMC。
- 与 NAND 版本区别：不生成 UBI `sysupgrade.bin`，不需要 UBI 专用 u-boot 分区布局。

---

## 🛠️ 日常修改指引

| 想要修改什么 | 修改哪个文件 |
| ---- | ---- |
| 调整网口、USB、eMMC 节点、硬件 | `diy/dts/meson-gxl-s905l3b-m302a.dts` |
| 修改镜像大小、输出格式、新增机型 | `diy/op/isos1.sh` |
| 增加 Luci 插件、开启 ksmbd、增减软件包 | `diy/m302a.config` |
| 更换国内镜像源、添加第三方插件源 | `diy/op/isos2.sh` |
| 修改编译资源、运行机系统、产物命名 | `.github/workflows/Build_m302a.yml` |

---

## ❌ 历史踩坑 & 常见报错汇总

1. `cp: cannot create regular file 'target/linux/amlogic/meson/dts/': No such file or directory`
   > 原因：ImmortalWrt 上游 meson 目录默认没有 dts 文件夹；解决方案：isos1.sh 增加 `mkdir -p` 创建目录。
2. `sed: can't read .config: No such file or directory`
   > 原因：isos2.sh 在复制 .config 之前执行；解决方案：调整顺序，先复制 m302a.config，再运行 isos2.sh。
3. 内核报错：`Cannot find DTS file meson-gxl-s905l3b-m302a`
   > 原因：DTS 存放路径和 ImmortalWrt 编译脚本检索路径不一致；核对 dts 存放位置。
4. 刷机后无法启动、找不到分区
   > 原因：DTS 内 eMMC 节点与板子实际硬件不匹配；或盒子实际是 NAND 版本，不能使用 eMMC 镜像配置。
5. 产物找不到 `sysupgrade.img.gz`
   > 原因：profile 里仍残留 UBI/NAND 参数导致镜像类型切换为 `sysupgrade.bin`；确认 isos1.sh 已移除 UBI 参数、`IMAGES := sysupgrade.img.gz`。
6. feeds 安装大量 telephony 电话相关包（kamailio、freeswitch）
   > 现象：日志大量 Installing package telephony，不是报错；不需要可以在 m302a.config 取消勾选 telephony 相关组件。

---

## 📜 许可证

- ImmortalWrt 遵循 GPLv2 开源协议。
- 本仓库脚本仅作为编译脚手架，仅供个人学习研究使用。

> （注：部分内容由豆包 AI 生成）
