#!/usr/bin/env bash
# Scripts/convert1.sh → 打包 U 盘启动镜像
set -e

# 回到仓库根目录（因为 op2.sh 在根目录跑，cwd 是 openwrt/）
cd "$(dirname "$0")/.."
REPO_ROOT="$(pwd)"

OUT="$REPO_ROOT/output"
mkdir -p "$OUT"

OPENWRT_BIN="$REPO_ROOT/openwrt/bin/targets/meson/meson8b"

# ---- 找编译产物 ----
ROOTFS_TAR=$(ls ${OPENWRT_BIN}/*-rootfs.tar.gz 2>/dev/null | head -1)
KERNEL=$(ls ${OPENWRT_BIN}/*zImage* 2>/dev/null | head -1)

if [ -z "$ROOTFS_TAR" ]; then
    echo "❌ 找不到 rootfs.tar.gz"
    echo "   请先运行 op2.sh 完成编译"
    exit 1
fi
if [ -z "$KERNEL" ]; then
    echo "❌ 找不到 zImage 内核"
    echo "   请确认 op2.sh 编译成功"
    exit 1
fi

echo "📦 rootfs: $(basename $ROOTFS_TAR)"
echo "📦 kernel: $(basename $KERNEL)"

# ---- 创建空白镜像 (1.2GB) ----
IMG="$OUT/ImmWrt-B60av21m-usb-$(date +%Y%m%d).img"
echo "📦 创建镜像: $IMG"
dd if=/dev/zero of="$IMG" bs=1M count=1200 status=progress

# ---- 写入 u-boot 到镜像头部 ----
UBOOT="$REPO_ROOT/device/b60av21m/uboot/u-boot.bin"
if [ -f "$UBOOT" ]; then
    dd if="$UBOOT" of="$IMG" bs=1 count=442 conv=notrunc 2>/dev/null || true
    dd if="$UBOOT" of="$IMG" bs=512 skip=1 seek=1 conv=notrunc 2>/dev/null || true
    echo "✅ u-boot 已写入镜像头部"
else
    echo "⚠️  未找到 u-boot.bin"
    echo "   下载: wget https://github.com/hzyitc/u-boot-onecloud/releases/latest/download/uboot.img -O device/b60av21m/uboot/u-boot.bin"
    echo "   没有 u-boot 镜像可能不能从U盘启动"
fi

# ---- 分区：跳过前4MB给u-boot ----
echo "📦 分区..."
cat <<EOF | sfdisk "$IMG" >/dev/null 2>&1
4M,256M,c
,,83
EOF

# ---- 关联 loop ----
LOOP=$(sudo losetup -f --show "$IMG")
sudo partprobe "$LOOP" 2>/dev/null || true

# ---- 格式化 ----
sudo mkfs.vfat -F 32 -n BOOT ${LOOP}p1 >/dev/null 2>&1
sudo mkfs.ext4 -L ROOTFS ${LOOP}p2 >/dev/null 2>&1

# ---- 挂载 ----
mkdir -p mnt_boot mnt_rootfs
sudo mount ${LOOP}p1 mnt_boot
sudo mount ${LOOP}p2 mnt_rootfs

# ---- 填充 boot 分区 ----
echo "📦 写入 boot 分区..."
sudo cp "$KERNEL" mnt_boot/zImage
sudo mkdir -p mnt_boot/dtb/amlogic

# 复制 dtb
DTB_SRC="$REPO_ROOT/device/b60av21m/dts"
if [ -d "$DTB_SRC" ] && ls "$DTB_SRC"/*.dtb >/dev/null 2>&1; then
    sudo cp "$DTB_SRC"/*.dtb mnt_boot/dtb/amlogic/
    echo "✅ dtb 已复制"
else
    echo "⚠️  device/b60av21m/dts/ 下没有 .dtb 文件"
    echo "   启动后可能需要手动指定 dtb"
fi

# uEnv.txt
sudo tee mnt_boot/uEnv.txt > /dev/null <<EOF
LINUX=/zImage
FDT=/dtb/amlogic/meson-gxl-s905l3b-b60av21m.dtb
APPEND=root=LABEL=ROOTFS rootfstype=ext4 console=ttyAML0,115200
EOF

# ---- 填充 rootfs ----
echo "📦 写入 rootfs..."
sudo tar -xzf "$ROOTFS_TAR" -C mnt_rootfs

# ---- 清理 ----
sync
sudo umount mnt_boot mnt_rootfs
sudo losetup -d "$LOOP"
rmdir mnt_boot mnt_rootfs 2>/dev/null || true

echo ""
echo "✅ U盘镜像已生成:"
echo "   $IMG"
echo ""
echo "写入U盘命令（确认 sdX 是U盘设备名！）:"
echo "   sudo dd if=$IMG of=/dev/sdX bs=1M status=progress"
echo "   sync"
