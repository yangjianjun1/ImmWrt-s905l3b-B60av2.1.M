include $(TOPDIR)/rules.mk

BOARD:=amlogic
BOARDNAME:=Amlogic Meson
SUBTARGETS:=meson
KERNEL_PATCHVER:=6.12

FEATURES:=audio ext4 squashfs usb usbgadget

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES += kmod-ata-core kmod-ata-ahci kmod-usb-core kmod-usb2 kmod-usb3

$(eval $(call BuildTarget))