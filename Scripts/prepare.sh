#!/usr/bin/env bash
# scripts/prepare.sh
# 职责：拉源码 + 更新/安装 feeds + 接入本仓库的设备/补丁/配置
# 不涉及编译（编译交给 build.sh）
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DEVICE="b60av21m"
OPENWRT_DIR="${OPENWRT_DIR:-openwrt}"
SRC_REPO="${SRC_REPO:-https://github.com/coolsnowwolf/lede.git}"
SRC_BRANCH="${SRC_BRANCH:-master}"

echo "📦 仓库根目录: $REPO_ROOT"
echo "🐧 源码目录:   $OPENWRT_DIR"

# ---------- 1. 拉取 OpenWrt 源码（幂等）----------
if [ -d "$OPENWRT_DIR/.git" ]; then
  echo "🔄 源码已存在，更新..."
  git -C "$OPENWRT_DIR" pull --ff-only || echo "⚠️  pull 失败，继续用现有代码"
else
  echo "⬇️  克隆源码: $SRC_REPO ($SRC_BRANCH)"
  rm -rf "$OPENWRT_DIR"
  git clone --depth=1 -b "$SRC_BRANCH" "$SRC_REPO" "$OPENWRT_DIR"
fi

cd "$OPENWRT_DIR"

# ---------- 2. 更新 & 安装 feeds ----------
echo "🌐 更新 feeds..."
./scripts/feeds update -a

echo "📥 安装 feeds..."
./scripts/feeds install -a

# ---------- 3. 接入本仓库的插件/自定义 feed（可选）----------
# 如果有第三方插件源，在 feeds.conf.default 追加后重新 update（示例保留）
# grep -q 'vernesong' feeds.conf.default || cat >> feeds.conf.default <<'EOF'
# src-git vernesong https://github.com/vernesong/OpenClash.git
# EOF
# ./scripts/feeds update -a
# ./scripts/feeds install -a

# ---------- 4. 复制补丁到 OpenWrt 正确路径 ----------
# 先确定内核大版本号（如 6.6）
KMAJMIN="$(grep -oE 'KERNEL_PATCHVER:=[0-9]+\.[0-9]+' target/linux/meson/Makefile 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')"
[ -z "$KMAJMIN" ] && KMAJMIN="$(grep -oE 'LINUX_VERSION-[0-9]+\.[0-9]+' .config 2>/dev/null | grep -oE '[0-9]+\.[0-9]+')"
[ -z "$KMAJMIN" ] && KMAJMIN="6.6"
echo "🧩 目标内核补丁目录: target/linux/meson/patches-${KMAJMIN}"

PATCH_DST="target/linux/meson/patches-${KMAJMIN}"
mkdir -p "$PATCH_DST"

# 优先用规划路径 patches/meson-gxl/，回退到仓库现有 target/linux/meson/
if [ -d "../patches/meson-gxl" ] && ls ../patches/meson-gxl/*.patch >/dev/null 2>&1; then
  cp ../patches/meson-gxl/*.patch "$PATCH_DST/"
  echo "✅ 已从 patches/meson-gxl/ 复制补丁"
elif [ -f "../target/linux/meson/200-mmc-fix-hs200-hs400es-timing.patch" ]; then
  cp ../target/linux/meson/200-mmc-fix-hs200-hs400es-timing.patch "$PATCH_DST/"
  echo "✅ 已从现有仓库路径复制 mmc 补丁"
fi

# ---------- 5. 接入设备树（dts）和预编译 dtb ----------
MESON_DTS_DIR="target/linux/meson/dts"
mkdir -p "$MESON_DTS_DIR"

# 5.1 如果有 dts 源码，复制进去（用于内核编译生成 dtb）
if ls ../device/${DEVICE}/dts/*.dts >/dev/null 2>&1; then
  cp ../device/${DEVICE}/dts/*.dts "$MESON_DTS_DIR/"
  echo "✅ 已复制设备树源码 (*.dts)"
fi

# 5.2 预编译 dtb 放到设备资源目录，供打包 U 盘时引用（不进内核构建）
DEVICE_RES_DIR="device/${DEVICE}/resources"
mkdir -p "$DEVICE_RES_DIR"
if [ -f "../device/${DEVICE}/dts/meson-gxl-s905l3b-${DEVICE}.dtb" ]; then
  cp "../device/${DEVICE}/dts/meson-gxl-s905l3b-${DEVICE}.dtb" "$DEVICE_RES_DIR/"
  echo "✅ 已复制预编译 dtb 到打包资源目录"
fi

# ---------- 6. 复制设备专属文件到固件（files/ 覆盖机制）----------
# OpenWrt 构建时，源码根目录的 files/ 会直接覆盖进 rootfs
if [ -d "../device/${DEVICE}/files" ]; then
  echo "📁 接入设备专属文件 (uci-defaults 等)..."
  mkdir -p files
  cp -rn "../device/${DEVICE}/files/." files/
fi

# ---------- 7. 复制默认配置 ----------
if [ -f "../configs/${DEVICE}.config" ]; then
  cp "../configs/${DEVICE}.config" .config
  echo "✅ 已写入 .config (来自 configs/${DEVICE}.config)"
elif [ -f "../onecloud.config" ]; then
  cp ../onecloud.config .config
  echo "⚠️  未找到 configs/${DEVICE}.config，暂用 onecloud.config"
fi

# ---------- 8. 生成 defconfig（不破坏已有自定义）----------
if [ -f .config ]; then
  make defconfig 2>/dev/null || echo "⚠️  defconfig 跳过（可稍后在 build.sh 里跑）"
fi

echo "✅ prepare.sh 完成。下一步：bash scripts/build.sh"
