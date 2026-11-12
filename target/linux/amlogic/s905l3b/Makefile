# SPDX-License-Identifier: GPL-2.0-only

ARCH:=aarch64
SUBTARGET:=s905l3b
BOARDNAME:=Amlogic S905L3B boards (64 bit)
CPU_TYPE:=cortex-a53

FEATURES+=ext4 usb mmc squashfs rootfs-part boot-part dt-overlay
KERNEL_PATCHVER:=6.12

KERNELNAME:=Image dtbs

DEFAULT_PACKAGES += kmod-dwmac-meson-gxl kmod-usb-dwc3 kmod-usb-dwc3-meson-g12a uboot-envtools

define Target/Description
	Build firmware images for Amlogic S905L3B SoC devices
	(M302A, M304A, CM211-1, CM311-1, B60-AV21M, etc.)
endef

include $(INCLUDE_DIR)/target.mk

$(eval $(call BuildTarget))