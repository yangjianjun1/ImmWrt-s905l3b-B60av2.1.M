#!/usr/bin/env bash
# scripts/diy-part.sh
# 在编译前修改 OpenWrt 源码默认值（IP、主机名、插件源等）
set -e

echo "🔧 开始 DIY 定制..."

# ---- 1. 添加第三方插件源 ----
echo "📦 添加插件源..."

# passwall / ssr-plus 等常用插件
git clone --depth=1 https://github.com/coolsnowwolf/luci package/luci-app-passwall 2>/dev/null || true

# 如果已经有 feeds 里的包，也可以在这里 clone 额外的
# git clone --depth=1 https://github.com/kenzok8/openwrt-packages package/openwrt-packages 2>/dev/null || true

# ---- 2. 默认 LAN IP ----
echo "🌐 设置默认 IP: 192.168.5.254"
sed -i 's/192.168.1.1/192.168.5.254/g' package/base-files/files/bin/config_generate

# ---- 3. 主机名 ----
echo "🏷️  设置主机名: B60av21m"
sed -i 's/OpenWrt/B60av21m/g' package/base-files/files/bin/config_generate

# ---- 4. 默认密码（留空 = 无密码，与 README 一致）----
# OpenWrt 默认就是空密码，无需额外操作
# 如果想设默认密码，取消下面注释（密码为 admin，需替换 hash）
# sed -i 's/$1$V4UetPzk$CtPv/p6BIVnM0Zd0m2f0e1/your_hash_here/g' package/base-files/files/etc/shadow

# ---- 5. 默认时区 ----
echo "🕐 设置时区: Asia/Shanghai"
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate

# ---- 6. 移除玩客云残留（确保干净）----
echo "🧹 清理旧设备残留..."
sed -i '/onecloud/d' package/base-files/files/bin/config_generate 2>/dev/null || true

# ---- 7. 确认 U 盘启动相关驱动已勾选（提醒用）----
echo "📋 请确认 .config 中已勾选以下选项（U 盘启动必需）："
echo "   CONFIG_PACKAGE_kmod-usb-storage=y"
echo "   CONFIG_PACKAGE_kmod-usb-storage-extras=y"
echo "   CONFIG_PACKAGE_kmod-fs-ext4=y"
echo "   CONFIG_PACKAGE_kmod-fs-vfat=y"
echo "   CONFIG_PACKAGE_block-mount=y"

# ---- 8. 生成默认网络配置（写入 files 目录，编译时自动包含）----
echo "📁 生成默认网络配置..."
mkdir -p files/etc/config

cat > files/etc/config/network <<'EOF'
config interface 'loopback'
    option device 'lo'
    option proto 'static'
    option ipaddr '127.0.0.1'
    option netmask '255.0.0.0'

config interface 'lan'
    option device 'eth0'
    option proto 'static'
    option ipaddr '192.168.5.254'
    option netmask '255.255.255.0'
    option ip6assign '60'
EOF

# 默认 DHCP 服务器
cat > files/etc/config/dhcp <<'EOF'
config dnsmasq
    option domainneeded '1'
    option boguspriv '1'
    option filterwin2k '0'
    option localise_queries '1'
    option rebind_protection '1'
    option rebind_localhost '1'
    option local '/lan/'
    option domain 'lan'
    option expandhosts '1'
    option nonegcache '0'
    option authoritative '1'
    option readethers '1'
    option leasefile '/tmp/dhcp.leases'
    option resolvfile '/tmp/resolv.conf.d/resolv.conf.auto'
    option nonwildcard '1'
    option localservice '1'

config dhcp 'lan'
    option interface 'lan'
    option start '100'
    option limit '150'
    option leasetime '12h'
    option dhcpv4 'server'
    option dhcpv6 'server'
    option ra 'server'
    option ra_management '1'

config dhcp 'wan'
    option interface 'wan'
    option ignore '1'
EOF

# 默认防火墙（允许 LAN 访问）
cat > files/etc/config/firewall <<'EOF'
config defaults
    option syn_flood '1'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'REJECT'

config zone
    option name 'lan'
    option network 'lan'
    option input 'ACCEPT'
    option output 'ACCEPT'
    option forward 'ACCEPT'

config zone
    option name 'wan'
    option network 'wan wan6'
    option input 'REJECT'
    option output 'ACCEPT'
    option forward 'REJECT'
    option masq '1'
    option mtu_fix '1'

config forwarding
    option src 'lan'
    option dest 'wan'
EOF

echo "✅ DIY 定制完成"
