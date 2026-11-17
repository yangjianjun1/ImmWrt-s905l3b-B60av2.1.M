#!/bin/bash
set -e

echo "===== run isos2.sh : feeds post process ====="

# ========== 1. 替换 feeds.conf 国内源（可选，解决拉包慢、超时） ==========
# sed -i 's|https://downloads.istoreos.com|https://mirror.xxx/istoreos|g' feeds.conf.default

# ========== 2. 追加第三方插件源示例（按需打开） ==========
# echo "src-git helloworld https://github.com/fw876/helloworld.git;main" >> feeds.conf.default
# ./scripts/feeds update helloworld
# ./scripts/feeds install -a

# ========== 3. 预先在配置里强制开启 kmod-fs-ksmbd（SMB共享） ==========
# 后面 m302a.config 会覆盖，这里做兜底
sed -i 's|# CONFIG_PACKAGE_kmod-fs-ksmbd is not set|CONFIG_PACKAGE_kmod-fs-ksmbd=y|g' .config
sed -i 's|CONFIG_PACKAGE_kmod-fs-ksmbd=n|CONFIG_PACKAGE_kmod-fs-ksmbd=y|g' .config

# ========== 4. 其它常用模块开关，按需增删 ==========
# sed -i 's|# CONFIG_PACKAGE_luci-app-samba4 is not set|CONFIG_PACKAGE_luci-app-samba4=y|g' .config
# sed -i 's|# CONFIG_PACKAGE_dockerd is not set|CONFIG_PACKAGE_dockerd=y|g' .config

# ========== 5. 删除无用包、清理冗余（可选） ==========
# sed -i 's|CONFIG_PACKAGE_xxxx=y|CONFIG_PACKAGE_xxxx=n|g' .config

echo "===== isos2.sh done ====="
