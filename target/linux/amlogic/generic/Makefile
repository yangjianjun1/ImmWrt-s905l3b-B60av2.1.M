# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 20xx OpenWrt.org

ARCH:=aarch64
SUBTARGET:=generic
BOARDNAME:=Amlogic Meson 64-bit SoC (generic)
CPU_TYPE:=cortex-a53

FEATURES+=ext4 usb usbgadget mmc squashfs rootfs-part boot-part dt-overlay
KERNEL_PATCHVER:=6.12

KERNELNAME:=Image dtbs

DEFAULT_PACKAGES += uboot-envtools partx-utils e2fsprogs blkdiscard

define Target/Description
	Build firmware images for Amlogic Meson 64-bit SoC devices
	(generic aarch64 base, covers S905/S905X/S905L3B family).
endef

include $(INCLUDE_DIR)/target.mk

$(eval $(call BuildTarget))