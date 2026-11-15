#!/bin/bash
# ============================================================================
# diy-part2.sh：加载 .config 之后执行（改 IP / 主机名 / 主题、增删软件包等）
# 参数：$1 = 默认管理 IP（可留空用官方默认 192.168.1.1）
#       $2 = 是否启用 ccache（true/false，由 workflow 传入）
# 执行时机：cp config -> .config -> 本脚本 -> make defconfig -> make download -> make
# ============================================================================

# 1) 修改默认管理 IP（需要改网段时取消注释并替换）
# sed -i "s/192.168.1.1/${1:-192.168.1.1}/g" package/base-files/files/bin/config_generate

# 2) 修改主机名
# sed -i 's/OpenWrt/M302A/g' package/base-files/files/bin/config_generate

# 3) 可选：更换 LuCI 主题（默认 bootstrap，需要 argon 等先在 part1 加 feed）
# sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' .config

# 4) 可选：编译后删除不想要的默认包（示例）
# rm -rf feeds/packages/net/{frp,tailscale}

echo ">>> diy-part2.sh 执行完成"
