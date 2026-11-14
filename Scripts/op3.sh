#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OPENWRT_DIR="${REPO_DIR}/openwrt"

echo "==> op3: 设置默认配置"

# 1. 默认 IP
cat > "${OPENWRT_DIR}/package/base-files/files/etc/uci-defaults/99-immwrt-defaults" << 'EOF'
#!/bin/sh
# 设置默认 LAN IP
uci set network.lan.ipaddr='192.168.5.254'
uci commit network

# 设置 root 密码为空（首次登录后提示设置）
# 如需预设密码，取消下面注释并填入加密后的密码
# echo 'root:$1$password' | chpasswd -e

# 主机名
uci set system.@system[0].hostname='ImmWrt-B60'
uci commit system
EOF
chmod +x "${OPENWRT_DIR}/package/base-files/files/etc/uci-defaults/99-immwrt-defaults"

# 2. 默认主题（如安装了 luci-theme-argon）
if [ -d "${OPENWRT_DIR}/feeds/luci/themes/luci-theme-argon" ]; then
  cat > "${OPENWRT_DIR}/package/base-files/files/etc/uci-defaults/98-theme" << 'EOF'
#!/bin/sh
uci set luci.main.mediaurlbase='/luci-static/argon'
uci commit luci
EOF
  chmod +x "${OPENWRT_DIR}/package/base-files/files/etc/uci-defaults/98-theme"
fi

echo "==> op3 done"