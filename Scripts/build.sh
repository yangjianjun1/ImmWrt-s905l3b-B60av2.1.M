# build.sh
cd openwrt

# 1. 复制补丁
# ...（前面讲过的补丁逻辑）

# 2. DIY 定制（在 feeds 安装后、编译前）
cd ..
bash scripts/diy-part.sh
cd openwrt

# 3. 复制设备专属文件
if [ -d "../device/b60av21m/files" ]; then
    cp -r ../device/b60av21m/files/* . 2>/dev/null || true
fi

# 4. 编译
make defconfig
make -j$(nproc) || make -j1 V=s
