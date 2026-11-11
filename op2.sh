#!/usr/bin/env bash
# op2.sh → 编译
set -e

cd openwrt

# 载入配置
cp ../onecloud.config .config   # 暂时还用这个名，后面改名

# 打 eMMC 补丁（U盘启动也建议打，后续可能写 eMMC）
mkdir -p target/linux/meson/patches
cp ../target/linux/meson/200-mmc-fix-hs200-hs400es-timing.patch \
   target/linux/meson/patches/

# 插件定制（把原来 op1.sh 里的 sed 操作搬过来）
sed -i 's/192.168.1.1/192.168.5.254/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/B60av21m/g' package/base-files/files/bin/config_generate

make defconfig
make -j$(nproc) || make -j1 V=s

echo "✅ 编译完成"
