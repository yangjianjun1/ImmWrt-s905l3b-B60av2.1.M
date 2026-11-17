#!/bin/bash
# isos1.sh：源码预处理阶段执行
set -e

# 复制M302A设备树到上游dts目录
cp -f ../diy/dts/meson-gxl-s905l3b-m302a.dts target/linux/amlogic/meson/dts/

# 追加M302A机型Profile到 meson Makefile
cat >> target/linux/amlogic/meson/Makefile <<EOF

define Device/m302a
  DEVICE_VENDOR := Amlogic
  DEVICE_MODEL := M302A (S905L3B)
  DEVICE_DTS := meson-gxl-s905l3b-m302a
  SOC := s905l3b
endef
TARGET_DEVICES += m302a
EOF
