#!/usr/bin/env bash
# scripts/convert1.sh
# 把 OpenWrt 编译产物打包成可启动 U 盘镜像
# 必须 sudo 运行（用到 losetup / mount / sfdisk）
set -euo pipefail

# ===================== 路径配置 =====================
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEVICE="b60av21m"

# 源码构建目录（prepare.sh 里克隆的）
OPENWRT_DIR="${REPO_ROOT}/openwrt"

# 设备资源
UBOOT_BIN="${REPO_ROOT}/device/${DEVICE}/uboot/u-boot.bin"
DTB_SRC="${REPO_ROOT}/device/${DEVICE}/dts/meson-gxl-s905l3b-${DEVICE}.dtb"
DTB_NAME="$(basename "$DTB_SRC")"

# 编译产物路径（lede 默认输出）
ZIMAGE="${OPENWRT_DIR}/bin/targets/meson/armv8/openwrt-meson-armv8-zImage"
ROOTFS_TAR="${OPENWRT_DIR}/bin/targets/meson/armv8/openwrt-meson-armv8-rootfs.tar.gz"

# 兜底：如果上面路径不存在，尝试其他常见命名
if [ ! -f "$ZIMAGE" ]; then
  ZIMAGE=$(find "$OPENWRT_DIR/bin" -name 'zImage' 2>/dev/null | head -1)
fi
if [ ! -f "$ROOTFS_TAR" ]; then
  ROOTFS_TAR=$(find "$OPENWRT_DIR/bin" -name '*rootfs.tar.gz' 2>/dev/null | head -1)
fi

# 输出
OUTPUT_DIR="${REPO_ROOT}/output"
OUTPUT_IMG="${OUTPUT_DIR}/ImmWrt-B60av21m-usb-tmp.img"

# 镜像参数
IMG_SIZE_MB=1200                      # 总大小 1.2G
BOOT_SIZE_MB=256                       # BOOT 分区 256M
UBOOT_SIZE_SECTORS=4096                # u-boot 占用前 4MB（4096 扇区）

# 挂载点
MNT_BOOT="$(mktemp -d /tmp/b60-boot.XXXXXX)"
MNT_ROOT="$(mktemp -d /tmp/b60-root.XXXXXX)"

# ===================== 前置检查 =====================
echo "🔍 检查依赖文件..."

[ -f "$UBOOT_BIN" ] || { echo "❌ 找不到 u-boot: $UBOOT_BIN"; exit 1; }
[ -f "$DTB_SRC" ]   || { echo "❌ 找不到 dtb: $DTB_SRC（请先 dtc 编译 dts）"; exit 1; }
[ -n "$ZIMAGE" ] && [ -f "$ZIMAGE" ] || { echo "❌ 找不到 zImage，先跑 build.sh"; exit 1; }
[ -n "$ROOTFS_TAR" ] && [ -f "$ROOTFS_TAR" ] || { echo "❌ 找不到 rootfs.tar.gz，先跑 build.sh"; exit 1; }

for tool in losetup sfdisk mkfs.vfat mkfs.ext4 bsdtar; do
  command -v "$tool" >/dev/null 2>&1 || { echo "❌ 缺少工具: $tool"; exit 1; }
done

mkdir -p "$OUTPUT_DIR"

# 清理函数
cleanup() {
  echo "🧹 清理挂载点..."
  sudo umount "$MNT_BOOT" 2>/dev/null || true
  sudo umount "$MNT_ROOT" 2>/dev/null || true
  if [ -n "${LOOP_DEV:-}" ]; then
    sudo losetup -d "$LOOP_DEV" 2>/dev/null || true
  fi
  rm -rf "$MNT_BOOT" "$MNT_ROOT" 2>/dev/null || true
}
trap cleanup EXIT

# ===================== 1. 建空镜像 =====================
echo "📀 创建镜像: $OUTPUT_IMG (${IMG_SIZE_MB}MB)"
rm -f "$OUTPUT_IMG"
dd if=/dev/zero of="$OUTPUT_IMG" bs=1M count=${IMG_SIZE_MB} status=progress

# ===================== 2. 写 u-boot 到镜像头部 =====================
echo "🔧 写入 u-boot（前 4MB 保留区）..."
# 注意：不覆盖 MBR 第 0 扇区，从第 1 扇区开始写
# 如果盒子不认，可改成 seek=0（会覆盖 MBR，需先备份分区表）
dd if="$UBOOT_BIN" of="$OUTPUT_IMG" bs=512 seek=1 conv=notrunc

# ===================== 3. 分区 =====================
echo "📐 分区（sfdisk）..."
# 单位：扇区（512B）。前 4MB 留给 u-boot，之后：
#   p1: BOOT  256M  FAT32 (LBA)
#   p2: ROOTFS 剩余  EXT4
BOOT_START=$UBOOT_SIZE_SECTORS
BOOT_SECTORS=$(( BOOT_SIZE_MB * 2048 ))
ROOT_START=$(( BOOT_START + BOOT_SECTORS ))

sfdisk "$OUTPUT_IMG" <<EOF
label: dos
unit: sectors

start=${BOOT_START}, size=${BOOT_SECTORS}, type=c
start=${ROOT_START}, type=83
EOF

# ===================== 4. 挂载 loop 设备 =====================
echo "🔗 挂载 loop 设备..."
LOOP_DEV="$(sudo losetup -fP --show "$OUTPUT_IMG")"
echo "   loop 设备: $LOOP_DEV"

# 等待分区节点出现
sleep 2
PART_BOOT="${LOOP_DEV}p1"
PART_ROOT="${LOOP_DEV}p2"

# ===================== 5. 格式化 =====================
echo "🖴 格式化分区..."
sudo mkfs.vfat -F 32 -n BOOT "$PART_BOOT"
sudo mkfs.ext4 -F -L ROOTFS "$PART_ROOT"

# ===================== 6. 挂载 =====================
echo "📂 挂载分区..."
sudo mount "$PART_BOOT" "$MNT_BOOT"
sudo mount "$PART_ROOT" "$MNT_ROOT"

# ===================== 7. 写 BOOT 分区 =====================
echo "📝 写入 BOOT 分区（zImage / dtb / uEnv.txt）..."

sudo mkdir -p "$MNT_BOOT/boot/dtb/amlogic"

# zImage
sudo cp "$ZIMAGE" "$MNT_BOOT/zImage"
echo "   ✅ zImage"

# dtb
sudo cp "$DTB_SRC" "$MNT_BOOT/boot/dtb/amlogic/$DTB_NAME"
echo "   ✅ $DTB_NAME"

# uEnv.txt
cat > /tmp/uEnv.txt <<EOF
# B60av2.1.M U 盘启动配置
dtb_file=/boot/dtb/amlogic/${DTB_NAME}

bootargs=console=ttyAML0,115200 earlycon=meson,0xc81004c0 root=/dev/sda2 rootfstype=ext4 rootwait rw fsck.repair=yes

bootcmd=booti 0x40800000 0x44000000 0x40000000
EOF
sudo cp /tmp/uEnv.txt "$MNT_BOOT/uEnv.txt"
echo "   ✅ uEnv.txt"

sudo sync

# ===================== 8. 解压 rootfs 到 ROOT 分区 =====================
echo "📦 解压 rootfs 到 ROOT 分区..."
sudo bsdtar -xpf "$ROOTFS_TAR" -C "$MNT_ROOT"
echo "   ✅ rootfs 解压完成"

# 确保必要目录
sudo mkdir -p "$MNT_ROOT/boot"

# 让设备树在 rootfs 里也有一份（部分系统从 /boot 读）
sudo cp "$DTB_SRC" "$MNT_ROOT/boot/$DTB_NAME" 2>/dev/null || true

sudo sync

# ===================== 9. 卸载 =====================
echo "📤 卸载分区..."
sudo umount "$MNT_BOOT"
sudo umount "$MNT_ROOT"
sudo losetup -d "$LOOP_DEV"
LOOP_DEV=""

# ===================== 10. 重命名输出 =====================
FINAL_IMG="${OUTPUT_DIR}/ImmWrt-B60av21m-usb-$(date +%Y%m%d-%H%M).img"
mv "$OUTPUT_IMG" "$FINAL_IMG"

echo "✅ 打包完成:"
ls -lh "$FINAL_IMG"
echo
echo "👉 写入 U 盘命令:"
echo "   sudo dd if=$FINAL_IMG of=/dev/sdX bs=1M status=progress conv=fsync"
