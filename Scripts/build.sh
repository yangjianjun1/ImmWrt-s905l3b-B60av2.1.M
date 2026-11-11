#!/usr/bin/env bash
set -e

DEVICE="b60av21m"
cd openwrt

# ---- 复制配置 ----
cp "../configs/${DEVICE}.config" .config

# ---- 安装 feeds ----
./scripts/feeds update -a
./scripts/feeds install -a

# ---- 复制补丁到 OpenWrt 正确路径 ----
# 从 .config 提取内核版本号（如 6.6）
KVER_LINE=$(grep '^CONFIG_LINUX_VERSION=' .config 2>/dev/null || true)
if [ -z "$KVER_LINE" ]; then
    # lede 默认内核版本，兜底
    KMAJMIN="6.6"
else
    KMAJMIN=$(echo "$KVER_LINE" | grep -oP '\d+\.\d+')
fi

PATCH_DIR="../patches/meson-gxl"
PATCH_DST="target/linux/meson/patches-${KMAJMIN}"

if [ -d "$PATCH_DIR" ] && ls "$PATCH_DIR"/*.patch >/dev/null 2>&1; then
    mkdir -p "$PATCH_DST"
    cp "$PATCH_DIR"/*.patch "$PATCH_DST/"
    echo "✅ 已复制补丁到 $PATCH_DST/"
    # 验证
    ls -la "$PATCH_DST"/
else
    echo "⚠️  未找到补丁目录 $PATCH_DIR，跳过"
fi

make defconfig

echo "📋 验证补丁是否会被应用："
make target/linux/prepare V=s 2>&1 | grep -i "200-mmc" || echo "⚠️  补丁未应用，请检查路径和内核版本"

make -j$(nproc) || make -j1 V=s
