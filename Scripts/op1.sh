#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENWRT_DIR="${REPO_DIR}/openwrt"

echo "==> op1: 注入 DTS 与平台补丁"

# 1. 复制 B60 专用 DTS
DTS_DIR="${OPENWRT_DIR}/target/linux/amlogic/files-6.12/arch/arm64/boot/dts/amlogic"
mkdir -p "${DTS_DIR}"
cp "${REPO_DIR}/target/linux/amlogic/files-6.12/arch/arm64/boot/dts/amlogic/meson-gxl-s905l3b-b60-av21m.dts" \
   "${DTS_DIR}/"

# 2. 应用 MMC 时序补丁（如仓库中已有）
PATCH_DIR="${REPO_DIR}/target/linux/meson"
if [ -f "${PATCH_DIR}/200-mmc-fix-hs200-hs400es-timing.patch" ]; then
  cp "${PATCH_DIR}/200-mmc-fix-hs200-hs400es-timing.patch" \
     "${OPENWRT_DIR}/target/linux/amlogic/patches-6.12/"
fi

echo "==> op1 done"