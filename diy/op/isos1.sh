#!/bin/bash
set -e
echo "===== isos1.sh start: add m302a s905l3b eMMC USB Boot ====="

# 1. 创建 dts 目录（ImmortalWrt 上游 meson 目录默认不带该文件夹）
mkdir -p target/linux/amlogic/meson/dts

# 2. 复制 eMMC 版本设备树到源码 dts 目录
cp -f ../diy/dts/meson-gxl-s905l3b-m302a.dts target/linux/amlogic/meson/dts/

# 3. 向 meson Makefile 追加 M302A profile，输出 sdcard.img.gz（U盘裸启动镜像）
cat >> target/linux/amlogic/meson/Makefile <<EOF

define Device/m302a
  DEVICE_VENDOR := Amlogic
  DEVICE_MODEL := M302A (S905L3B eMMC USB Boot)
  DEVICE_DTS := meson-gxl-s905l3b-m302a
  SOC := s905l3b
  KERNEL := kernel-bin | lzma | uImage lzma
  IMAGE_SIZE := 256m
  IMAGES := sdcard.img.gz
  IMAGE/sdcard.img.gz := aml-imgpack | gzip
endef
TARGET_DEVICES += m302a
EOF

echo "===== isos1.sh finished ====="
