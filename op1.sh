#!/usr/bin/env bash
# op1.sh → 准备源码和 feeds
set -e

git clone --depth=1 https://github.com/coolsnowwolf/lede openwrt
cd openwrt

./scripts/feeds update -a
./scripts/feeds install -a

echo "✅ 源码和 feeds 就绪"
