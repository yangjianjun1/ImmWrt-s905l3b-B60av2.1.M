#!/bin/bash
# diy-op1.sh: 在 feeds update 之前执行
# 作用：加软件源、不碰 git 分支

echo "===== DIY-P1: 添加软件源 ====="

# helloworld (ssr-plus / passwall 依赖)
echo 'src-git helloworld https://github.com/fw876/helloworld' >> feeds.conf.default

# 如果需要其他 feed，在这里加，例如：
# echo 'src-git kenzo https://github.com/kenzok8/openwrt-packages' >> feeds.conf.default

echo "===== DIY-P1: 完成 ====="
