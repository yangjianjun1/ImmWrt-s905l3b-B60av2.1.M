#!/bin/bash
set -e
echo "===== run isos2.sh : feeds post process ====="

# 替换国内镜像源（按需开启）
# sed -i 's|https://downloads.immortalwrt.org|https://mirror.xxx/immortalwrt|g' feeds.conf.default

# 追加第三方插件源示例
# echo "src-git helloworld https://github.com/fw876/helloworld.git;main" >> feeds.conf.default
# ./scripts/feeds update helloworld
# ./scripts/feeds install -a

echo "===== isos2.sh done ====="
