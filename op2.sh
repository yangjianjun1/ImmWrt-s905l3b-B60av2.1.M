#!/usr/bin/env bash
set -e

# ---- 路径定义 ----
SRC=~/immortalwrt
REPO=~/ImmWrt-s905l3b-B60av2.1.M   # 你的仓库工作区（Actions 里是 $GITHUB_WORKSPACE）
BOARD=s905l3b
DTB=meson-gxl-s905l3b-b60-av21m

echo "[op2] Repo: $REPO"
echo "[op2] Src:  $SRC"

# ---- 0. 前置检查 ----
[ -d "$REPO/target/linux/amlogic" ] || { echo "[op2] ERROR: repo platform dir missing"; exit 1; }
[ -f "$REPO/target/linux/amlogic/files-6.12/arch/arm64/boot/dts/amlogic/$DTB.dts" ] \
  || { echo "[op2] ERROR: DTS not found"; exit 1; }

# ---- 1. 同步 DTS 覆盖目录（files-6.12）----
echo "[op2] Syncing DTS overlays..."
mkdir -p $SRC/target/linux/amlogic/files-6.12
cp -rn $REPO/target/linux/amlogic/files-6.12/* \
      $SRC/target/linux/amlogic/files-6.12/ 2>/dev/null || \
cp -r $REPO/target/linux/amlogic/files-6.12/* \
      $SRC/target/linux/amlogic/files-6.12/

# ---- 2. 同步 s905l3b subtarget 定义 ----
echo "[op2] Syncing subtarget..."
mkdir -p $SRC/target/linux/amlogic/$BOARD
cp $REPO/target/linux/amlogic/$BOARD/target.mk \
   $SRC/target/linux/amlogic/$BOARD/

# ---- 3. 顶层 Makefile 注册 subtarget ----
echo "[op2] Patching platform Makefile SUBTARGETS..."
AMLOGIC_MK=$SRC/target/linux/amlogic/Makefile
if grep -q "^SUBTARGETS" $AMLOGIC_MK; then
  # 避免重复加
  grep -q "$BOARD" <<< "$(grep '^SUBTARGETS' $AMLOGIC_MK)" \
    || sed -i "s/^SUBTARGETS:=/SUBTARGETS:=${BOARD} /" $AMLOGIC_MK
else
  echo "SUBTARGETS:=generic ${BOARD} meson8b" >> $AMLOGIC_MK
fi

# ---- 4. image/Makefile 注册设备（防重复）----
echo "[op2] Registering device in image/Makefile..."
IMG_MK=$SRC/target/linux/amlogic/image/Makefile
if ! grep -q "$DTB" $IMG_MK; then
  cat >> $IMG_MK << EOF

define Device/$DTB
  DEVICE_VENDOR := B60
  DEVICE_MODEL := AV21M (S905L3B)
  DEVICE_DTS := amlogic/$DTB
  DEVICE_PACKAGES := kmod-dwmac-meson-gxl kmod-usb-dwc3 kmod-usb-dwc3-meson-g12a
  KERNELNAME := Image
  IMAGES := sysupgrade.img.gz
endef
TARGET_DEVICES += $DTB
EOF
fi

# ---- 5. 配置：用仓库里的 b60av21m.config ----
echo "[op2] Applying config..."
cp $REPO/b60av21m.config $SRC/.config
cd $SRC

# 确保关键选项被选中（防止 defconfig 被平台默认覆盖）
cat >> .config << EOF
CONFIG_TARGET_amlogic=y
CONFIG_TARGET_amlogic_$BOARD=y
CONFIG_TARGET_DEVICE_amlogic_device_${DTB}=y
EOF

# ---- 6. 强制重扫（OpenWrt 官方要求）----
touch target/linux/*/Makefile
make target/linux/clean prepare
make defconfig

echo "[op2] ✅ s905l3b / B60-AV21M target ready."