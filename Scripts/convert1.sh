#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-2.0-only
# ImmWrt B60 AV21M — MBR image generator
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENWRT_DIR="${REPO_DIR}/openwrt"
OUTPUT_DIR="${REPO_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

# ── 路径配置（修正：meson/generic，不是 amlogic/s905l3b） ──
TARGET_DIR="${OPENWRT_DIR}/bin/targets/meson/generic"

UBOOT="${REPO_DIR}/board/b60av21m/u-boot-s905x-s912.bin"
ROOTFS_TAR=$(ls ${TARGET_DIR}/openwrt-*-rootfs.tar.gz 2>/dev/null | head -1)
KERNEL=$(ls ${TARGET_DIR}/*b60*av21m*uImage 2>/dev/null | head -1)
DTB=$(ls ${TARGET_DIR}/*b60*av21m*.dtb 2>/dev/null | head -1)
# 兜底：从源码树里找 DTB（如果没作为独立产物输出）
if [ -z "${DTB}" ] || [ ! -f "${DTB}" ]; then
    DTB="${REPO_DIR}/target/linux/meson/files-6.12/arch/arm64/boot/dts/amlogic/meson-gxl-s905l3b-b60-av21m.dtb"
fi
BOOT_SCR="${REPO_DIR}/board/b60av21m/boot.scr"
UENV="${REPO_DIR}/board/b60av21m/uEnv.txt"

# ── 前置检查（改进：变量为空时显示"未找到"而不是空白） ──
check_file() {
    local var_name="$1"
    local file_path="$2"
    if [ -z "${file_path}" ] || [ ! -f "${file_path}" ]; then
        echo "ERROR: 缺少文件 [${var_name}] = ${file_path:-<空>}"
        return 1
    fi
    echo "  ✓ ${var_name}: ${file_path}"
    return 0
}

echo "==> 检查依赖文件..."
check_file "ROOTFS_TAR" "${ROOTFS_TAR}" || MISSING=1
check_file "KERNEL"     "${KERNEL}"     || MISSING=1
check_file "DTB"        "${DTB}"        || MISSING=1
check_file "BOOT_SCR"   "${BOOT_SCR}"   || MISSING=1
check_file "UENV"       "${UENV}"       || MISSING=1

if [ "${MISSING}" = "1" ]; then
    echo ""
    echo "编译产物目录内容："
    ls -R "${TARGET_DIR}/" 2>/dev/null || echo "  (目录不存在: ${TARGET_DIR})"
    exit 1
fi

IMG_NAME="ImmWrt-B60av21m-$(date +%Y%m%d).img"
IMG_PATH="${OUTPUT_DIR}/${IMG_NAME}"

echo ""
echo "==> 创建 ${IMG_NAME} (4096M, MBR)"

# ── 空镜像 ──
dd if=/dev/zero of="${IMG_PATH}" bs=1M count=4096 status=progress

# ── MBR 分区表（Amlogic 标准：预留 128MiB 给 U-Boot） ──
parted -s "${IMG_PATH}" mklabel msdos
parted -s "${IMG_PATH}" mkpart primary fat32 128MiB 641MiB
parted -s "${IMG_PATH}" mkpart primary btrfs 641MiB 100%
parted -s "${IMG_PATH}" set 1 boot on

# ── loop 映射 ──
LOOP=$(losetup -f --show "${IMG_PATH}")
partx -a "${LOOP}"

# ── 格式化 ──
mkfs.vfat -n BOOT "${LOOP}p1"
mkfs.btrfs -L rootfs -f "${LOOP}p2"

# ── 挂载 ──
MOUNT_BOOT="/tmp/b60_boot_$$"
MOUNT_ROOT="/tmp/b60_root_$$"
mkdir -p "${MOUNT_BOOT}" "${MOUNT_ROOT}"
mount "${LOOP}p1" "${MOUNT_BOOT}"
mount "${LOOP}p2" "${MOUNT_ROOT}"

# ── 写入 U-Boot（MBR 标准偏移） ──
if [ -f "${UBOOT}" ]; then
    dd if="${UBOOT}" of="${LOOP}" bs=1 count=444 conv=notrunc 2>/dev/null
    dd if="${UBOOT}" of="${LOOP}" bs=512 skip=1 seek=1 conv=notrunc 2>/dev/null
    echo "==> U-Boot written"
else
    echo "WARN: U-Boot not found, skipping"
fi

# ── 写入启动文件 ──
mkdir -p "${MOUNT_BOOT}/dtb/amlogic"
cp "${KERNEL}"     "${MOUNT_BOOT}/uImage"
cp "${DTB}"        "${MOUNT_BOOT}/dtb/amlogic/$(basename "${DTB}")"
cp "${BOOT_SCR}"   "${MOUNT_BOOT}/boot.scr"
cp "${UENV}"       "${MOUNT_BOOT}/uEnv.txt"

# initramfs（可选）
INITRAMFS=$(ls ${TARGET_DIR}/*initramfs* 2>/dev/null | head -1)
if [ -n "${INITRAMFS}" ] && [ -f "${INITRAMFS}" ]; then
    cp "${INITRAMFS}" "${MOUNT_BOOT}/uInitrd"
    echo "==> uInitrd copied"
fi

# ── 解压 rootfs ──
echo "==> Extracting rootfs..."
tar -xzf "${ROOTFS_TAR}" -C "${MOUNT_ROOT}"

# ── 清理 ──
umount "${MOUNT_BOOT}" "${MOUNT_ROOT}"
rmdir "${MOUNT_BOOT}" "${MOUNT_ROOT}"
partx -d "${LOOP}"
losetup -d "${LOOP}"

# ── 压缩 ──
cd "${OUTPUT_DIR}"
xz -z -9 -T0 "${IMG_NAME}"
sha256sum "${IMG_NAME}.xz" > "${IMG_NAME}.xz.sha256"

echo "==> Done: ${IMG_NAME}.xz ($(ls -lh "${IMG_NAME}.xz" | awk '{print $5}'))"
