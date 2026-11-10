#!/bin/bash
set -euo pipefail

echo "::group::🔄 B60 固件转换 - U 盘启动包"

SRC_DIR="openwrt/bin/targets/amlogic/meson"
OUT_DIR="artifacts"
mkdir -p "$OUT_DIR"

# ===== 1. 找镜像 =====
factory_gz=$(find "$SRC_DIR" -name "*factory*.img.gz" | head -n1)
sysupgrade_gz=$(find "$SRC_DIR" -name "*sysupgrade*.img.gz" | head -n1)

if [ -z "$factory_gz" ]; then
  echo "⚠️ 未找到 factory 镜像，尝试用 sysupgrade 替代..."
  if [ -z "$sysupgrade_gz" ]; then
    echo "❌ 未找到任何 .img.gz 产物"
    echo "📂 当前产物目录内容："
    ls -R "$SRC_DIR/" 2>/dev/null || true
    exit 1
  fi
  factory_gz="$sysupgrade_gz"
fi

echo "📂 源镜像：$factory_gz"

# ===== 2. 解压 =====
gunzip -f "$factory_gz"
factory_img="${factory_gz%.gz}"
echo "✅ 解压完成：$factory_img"

# ===== 3. 验证镜像（可选，方便调试）=====
loop=$(sudo losetup --find --show --partscan "$factory_img" 2>/dev/null || true)
if [ -n "$loop" ]; then
  echo "📋 镜像分区信息："
  sudo fdisk -l "$loop" 2>/dev/null | head -20 || true
  sudo losetup -d "$loop" 2>/dev/null || true
fi

# ===== 4. 输出 U 盘启动镜像 =====
VERSION=$(date +%Y%m%d-%H%M)
usb_img="$OUT_DIR/B60av2.1.M-usb-${VERSION}.img"
cp "$factory_img" "$usb_img"

# 压缩版（方便下载）
gzip -9 -c "$factory_img" > "$OUT_DIR/B60av2.1.M-usb-${VERSION}.img.gz"

echo "✅ U 盘启动镜像：$usb_img"
echo "✅ 压缩版：$OUT_DIR/B60av2.1.M-usb-${VERSION}.img.gz"

# ===== 5. 处理 sysupgrade =====
if [ -n "$sysupgrade_gz" ] && [ "$sysupgrade_gz" != "$factory_gz" ]; then
  gunzip -f "$sysupgrade_gz"
  sysupgrade_img="${sysupgrade_gz%.gz}"
  cp "$sysupgrade_img" "$OUT_DIR/B60av2.1.M-sysupgrade-${VERSION}.img"
  gzip -9 -c "$sysupgrade_img" > "$OUT_DIR/B60av2.1.M-sysupgrade-${VERSION}.img.gz"
  echo "✅ sysupgrade 镜像已生成"
fi

# ===== 6. 校验和 =====
cd "$OUT_DIR"
sha256sum *.img *.img.gz > sha256sums 2>/dev/null || true
cd ..

# ===== 7. 清理编译中间产物（只保留 artifacts/ 里的）=====
rm -f "$factory_img"
[ -n "$sysupgrade_gz" ] && [ "$sysupgrade_gz" != "$factory_gz" ] && rm -f "${sysupgrade_gz%.gz}" || true

echo ""
echo "🎉 转换完成！最终产物："
ls -lh "$OUT_DIR"/*.{img,img.gz,sha256sums} 2>/dev/null || ls -lh "$OUT_DIR"/

echo "::endgroup::"
