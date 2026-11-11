#!/usr/bin/env bash
# pack-usb.sh → 打包 U 盘启动镜像
set -e

OUT="output"
mkdir -p "$OUT"

OPENWRT_BIN="openwrt/bin/targets/meson/meson8b"

# 找编译产物
ROOTFS_TAR=$(ls ${OPENWRT_BIN}/*-rootfs.tar.gz 2>/dev/null | head -1)
KERNEL=$(ls ${OPENWRT_BIN}/*zImage* 2>/dev/null | head -1)
[ -z "$ROOTFS_TAR" ] && { echo "❌ 找不到 rootfs.tar.gz"; exit 1; }
[ -z "$KERNEL" ] && { echo "❌ 找不到内核"; exit 1; }

echo "📦 rootfs: $ROOTFS_TAR"
echo "📦 kernel: $KERNEL"

# 创建空白镜像（1.2GB，够用）
IMG="$OUT/ImmWrt-B60av21m-usb-$(date +%Y%m%d).img"
dd if=/dev/zero of="$IMG" bs=1M count=1200 status=progress

# 分区：第一个分区 FAT32 (boot, 256MB)，第二个分区 EXT4 (rootfs, 剩余)
# 用 sfdisk 分区
cat <<EOF | sfdisk "$IMG"
,256M,c
,,83
EOF

# 关联 loop 设备
LOOP=$(sudo losetup -f --show "$IMG")
sudo partprobe "$LOOP"

# 格式化
sudo mkfs.vfat -F 32 -n BOOT ${LOOP}p1
sudo mkfs.ext4 -L ROOTFS ${LOOP}p2

# 挂载
mkdir -p mnt_boot mnt_rootfs
sudo mount ${LOOP}p1 mnt_boot
sudo mount ${LOOP}p2 mnt_rootfs

# ---- 填充 boot 分区 ----
sudo mkdir -p mnt_boot/dtb/amlogic

# 复制内核
sudo cp "$KERNEL" mnt_boot/zImage

# 复制 dtb（如果有）
if [ -d "device/b60av21m/dts" ]; then
    sudo cp device/b60av21m/dts/*.dtb mnt_boot/dtb/amlogic/ 2>/dev/null || true
fi

# uEnv.txt
sudo tee mnt_boot/uEnv.txt > /dev/null <<'EOF'
LINUX=/zImage
FDT=/dtb/amlogic/meson-gxl-s905l3b-b60av21m.dtb
APPEND=root=LABEL=ROOTFS rootfstype=ext4 console=ttyAML0,115200
EOF

# ---- 填充 rootfs ----
sudo tar -xzf "$ROOTFS_TAR" -C mnt_rootfs

# 写入完成
sync
sudo umount mnt_boot mnt_rootfs
sudo losetup -d "$LOOP"
rmdir mnt_boot mnt_rootfs 2>/dev/null || true

echo "✅ U盘镜像已生成: $IMG"
echo "   写入U盘: sudo dd if=$IMG of=/dev/sdX bs=1M status=progress"
