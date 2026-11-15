# patches 目录说明

## 目录用途
存放需要在编译前替换/打补丁的自定义文件，当前主要用于 N1 设备树（DTS）。

## 自定义 DTS 文件
文件名必须固定为：

```
meson-gxl-s905d-phicomm-n1.dts
```

把你修改好的 DTS 放到本目录后，`.github/workflows/build.yml` 会在拉取源码后
**自动探测源码内真实路径并覆盖**，无需手写绝对路径。

> 不放该文件时，编译自动使用上游默认 DTS，不影响固件生成。

## 如何获取上游基准 DTS（修改前先复制一份）
在本地克隆源码后执行：

```bash
git clone -b openwrt-24.10 --single-branch https://github.com/immortalwrt/immortalwrt.git openwrt
cd openwrt
find . -name 'meson-gxl-s905d-phicomm-n1.dts'
```

把找到的文件复制到本目录，再在副本上修改即可。

## N1 常见 DTS 优化点
- 网口 PHY 复位延时（解决偶发断网/不识别网线）
- 关闭 HDMI、音频、红外等无用外设
- 调整 CMA 预留内存大小
- 配置串口、LED 指示灯

## 注意事项
1. DTS 内 `#include` / `#include "meson-gxl.dtsi"` 等依赖不要删除。
2. 文件保存为 **LF 换行**（Windows 记事本会带 CRLF，可能导致 dtc 编译报错）。
3. 文件名必须与默认 DTS 完全一致，profile 绑定的是这个 dtb。
4. DTS 语法错误会在编译阶段由 dtc 直接报错，日志中可定位到具体行。

## 备选：补丁方式（只改几行时推荐）
若只做小改动，可生成 diff 补丁 `900-n1-custom-dts.patch` 放本目录，
在 workflow 中改用 `git apply ../patches/900-n1-custom-dts.patch` 应用。
