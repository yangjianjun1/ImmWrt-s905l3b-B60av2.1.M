# 克隆完源码后
SRC=~/immortalwrt

# 1. 覆盖 dts（带内核版本目录）
cp -r target/linux/amlogic/files-6.1/*  $SRC/target/linux/amlogic/files-6.1/

# 2. 追加设备定义（或整文件覆盖 image/Makefile）
cat >> $SRC/target/linux/amlogic/image/Makefile << 'EOF'
define Device/meson-gxl-s905l3b-b60-av21m
  DEVICE_VENDOR := B60
  DEVICE_MODEL := AV21M
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-b60-av21m
  DEVICE_PACKAGES := kmod-dwmac-meson-gxl
endef
TARGET_DEVICES += meson-gxl-s905l3b-b60-av21m
EOF

# 3. 用 b60av21m.config
cp b60av21m.config $SRC/.config
cd $SRC && make defconfig