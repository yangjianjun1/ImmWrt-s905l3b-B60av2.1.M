#!/bin/bash
set -e
echo "===== isos1.sh start: add m302a s905l3b NAND UBI ====="

# 【新增】先创建dts目录（适配ImmortalWrt，原生没有这个文件夹）
mkdir -p target/linux/amlogic/meson/dts

# 复制dts到源码内的dts目录
cp -f ../diy/dts/meson-gxl-s905l3b-m302a.dts target/linux/amlogic/meson/dts/

# 追加带UBI NAND分区的M302A profile到 meson Makefile
cat >> target/linux/amlogic/meson/Makefile <<EOF

define Device/m302a
  DEVICE_VENDOR := Amlogic
  DEVICE_MODEL := M302A (S905L3B NAND)
  DEVICE_DTS := meson-gxl-s905l3b-m302a
  SOC := s905l3b
  KERNEL := kernel-bin | lzma | uImage lzma
  IMAGE_SIZE := 128m
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  SUBPAGESIZE := 2048
  VID_HDR_OFFSET := 2048
  IMAGES := sysupgrade.bin
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += m302a
EOF

echo "===== isos1.sh finished ====="
