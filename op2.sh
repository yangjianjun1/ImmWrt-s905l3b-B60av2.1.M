#!/bin/bash
# diy-op2.sh: feeds update 之后、.config 之前
# 作用：替换/添加软件包

set -e  # 任何命令失败立即退出

echo "===== DIY-P2: 开始 ====="

# ── Golang 升级 ────────────────────────────
echo "--- 升级 Golang 到 1.26.x ---"
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang.git -b 26.x feeds/packages/lang/golang

# ── PassWall ───────────────────────────────
echo "--- 部署 PassWall ---"
# 删除 feeds 自带的包（用正确的包名）
rm -rf feeds/packages/net/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls,smartdns}

# 删除可能已安装的
[ -d package/feeds/packages ] && rm -rf package/feeds/packages/{xray-core,v2ray-geodata,sing-box,chinadns-ng,dns2socks,hysteria,ipt2socks,microsocks,naiveproxy,shadowsocks-libev,shadowsocks-rust,shadowsocksr-libev,simple-obfs,tcping,trojan-plus,tuic-client,v2ray-plugin,xray-plugin,geoview,shadow-tls,smartdns} 2>/dev/null || true

# 拉取 passwall
git clone https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git package/chajian/passwall-packages
git clone https://github.com/Openwrt-Passwall/openwrt-passwall.git package/chajian/passwall-luci

# ── EasyTier ───────────────────────────────
echo "--- 部署 EasyTier ---"
git clone https://github.com/EasyTier/luci-app-easytier.git package/chajian/easytier || echo "EasyTier 克隆失败，跳过"

# ── 锐捷认证 ───────────────────────────────
echo "--- 部署 MentoHUST ---"
git clone https://github.com/sbwml/luci-app-mentohust.git package/chajian/mentohust

# ── OpenAppFilter ──────────────────────────
echo "--- 部署 OpenAppFilter ---"
rm -rf feeds/packages/net/open-app-filter
[ -d package/feeds/packages ] && rm -rf package/feeds/packages/open-app-filter 2>/dev/null || true
git clone https://github.com/destan19/OpenAppFilter.git package/chajian/OpenAppFilter

# ── socat ──────────────────────────────────
echo "--- 部署 luci-app-socat ---"
git clone https://github.com/chenmozhijin/luci-app-socat.git package/chajian/socat

# ── Tailscale ──────────────────────────────
echo "--- 部署 Tailscale ---"
if [ -f feeds/packages/net/tailscale/Makefile ]; then
    sed -i '/\/etc\/init\.d\/tailscale/d;/\/etc\/config\/tailscale/d;' feeds/packages/net/tailscale/Makefile
fi
git clone https://github.com/asvow/luci-app-tailscale.git package/chajian/tailscale/luci-app-tailscale

# ── Argon 主题 ─────────────────────────────
echo "--- 部署 Argon 主题 ---"
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
[ -d package/feeds/luci ] && rm -rf package/feeds/luci/luci-theme-argon package/feeds/luci/luci-app-argon-config 2>/dev/null || true

git clone https://github.com/sbwml/luci-theme-argon.git package/chajian/argon

# ── 系统默认配置修改 ───────────────────────
echo "--- 修改系统默认配置 ---"

# 默认 IP
sed -i 's/192.168.1.1/192.168.5.254/g' package/base-files/files/bin/config_generate

# 主机名
sed -i "s/hostname='.*'/hostname='B60'/g" package/base-files/files/bin/config_generate

# 时区
sed -i "s/timezone='.*'/timezone='CST-8'/g" package/base-files/files/bin/config_generate
grep -q "zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate || \
    sed -i "/.*timezone='CST-8'.*/a\ set system.@system[-1].zonename='Asia/Shanghai'" package/base-files/files/bin/config_generate

# 固件名称
sed -i 's/NAME="%D"/NAME="ImmortalWrt-B60"/g' package/base-files/files/usr/lib/os-release
sed -i 's/PRETTY_NAME="%D %V"/PRETTY_NAME="ImmortalWrt-B60 %V"/g' package/base-files/files/usr/lib/os-release
sed -i 's/OPENWRT_RELEASE="%D %V %C"/OPENWRT_RELEASE="ImmortalWrt-B60 %V %C"/g' package/base-files/files/usr/lib/os-release

# 默认主题（argon）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci-light/Makefile 2>/dev/null || true

echo "===== DIY-P2: 完成 ====="
