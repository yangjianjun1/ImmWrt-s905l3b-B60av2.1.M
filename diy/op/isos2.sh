#!/bin/bash
set -e
echo "===== run isos2.sh : feeds post process ====="

# ========== 1. 替换 feeds.conf 国内镜像源（按需开启） ==========
# sed -i 's|https://downloads.immortalwrt.org|https://你的镜像地址/immortalwrt|g' feeds.conf.default

# ========== 2. 追加第三方插件源示例（按需开启） ==========
# echo "src-git helloworld https://github.com/fw876/helloworld.git;main" >> feeds.conf.default
# ./scripts/feeds update helloworld
# ./scripts/feeds install -a

# ========== 3. 配置开关兜底（.config 已先于本脚本复制到位，可安全使用 sed） ==========
# 开启 ksmbd SMB 共享内核模块（若 m302a.config 已配置，以此为准不重复）
# sed -i 's|# CONFIG_PACKAGE_kmod-fs-ksmbd is not set|CONFIG_PACKAGE_kmod-fs-ksmbd=y|g' .config
# sed -i 's|CONFIG_PACKAGE_kmod-fs-ksmbd=n|CONFIG_PACKAGE_kmod-fs-ksmbd=y|g' .config

echo "===== isos2.sh done ====="
