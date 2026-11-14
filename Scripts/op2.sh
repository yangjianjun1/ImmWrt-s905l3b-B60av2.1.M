#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENWRT_DIR="${REPO_DIR}/openwrt"

echo "==> op2: 写入 B60 设备定义"

# 1. 注入 image/Makefile 设备段
MAKE_FILE="${OPENWRT_DIR}/target/linux/amlogic/image/Makefile"

# 检查是否已注入，避免重复
if ! grep -q "b60av21m" "${MAKE_FILE}"; then
  cat >> "${MAKE_FILE}" << 'EOF'

define Device/b60av21m
  DEVICE_VENDOR := B60
  DEVICE_MODEL := av2.1M (s905l3b)
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-b60-av21m
  DEVICE_PACKAGES := kmod-brcmfmac wpad-openssl kmod-usb-net-rtl8150 kmod-usb-storage
  UBOOT := u-boot-s905x-s912.bin
  IMAGE_SIZE := 4096M
  SUPPORTED_DEVICES := b60av21m
endef
TARGET_DEVICES += b60av21m
EOF
fi

# 2. 确保 target.mk 存在
TARGET_MK="${OPENWRT_DIR}/target/linux/amlogic/s905l3b/target.mk"
mkdir -p "$(dirname "${TARGET_MK}")"
if [ ! -f "${TARGET_MK}" ]; then
  cat > "${TARGET_MK}" << 'EOF'
BOARDNAME := B60 (s905l3b)
FEATURES += usb storage squashfs btrfs

DEFAULT_PACKAGES += kmod-usb-core kmod-usb2 kmod-usb-storage
EOF
fi

echo "==> op2 done"