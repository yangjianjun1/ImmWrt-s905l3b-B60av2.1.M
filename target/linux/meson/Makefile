# SPDX-License-Identifier: GPL-2.0-only

include $(TOPDIR)/rules.mk

ARCH:=aarch64
BOARD:=amlogic
BOARDNAME:=Amlogic Meson
FEATURES:=ext4 usb usbgadget display gpio pci pcie rtc squashfs
SUBTARGETS:=meson

KERNEL_PATCHVER:=6.12

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += \
    kmod-amlogic-thermal \
    kmod-brcmfmac wpad-basic-mbedtls \
    uboot-envtools

$(eval $(call BuildTarget))