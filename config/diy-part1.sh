#!/bin/bash
# ============================================================================
# diy-part1.sh：更新 feeds 之前执行（改默认源、删包、加 feed 等）
# 执行时机：clone 源码 -> 本脚本 -> feeds update -a -> feeds install -a
# ============================================================================

# 1) 可选：追加第三方 feed 源（默认注释，需要时去掉行首 #）
# sed -i '$a src-git lienol https://github.com/Lienol/openwrt-package' feeds.conf.default

# 2) 可选：删除不需要的内置包（示例，按需放开）
# rm -rf package/utils/{ucode,fbtest}

# 3) 替换下载源为国内镜像（可选，加速 dl 下载）
# sed -i 's/https:\/\/downloads.openwrt.org/https:\/\/mirrors.tuna.tsinghua.edu.cn\/openwrt/g' feeds.conf.default

echo ">>> diy-part1.sh 执行完成"
