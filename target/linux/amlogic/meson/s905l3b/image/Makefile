include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

define Device/b60_av21m
  DEVICE_VENDOR := Unknown
  DEVICE_MODEL := B60 AV2.1M
  DEVICE_DTS := meson-gxl-s905l3b-B60av2.1.M
  DEVICE_PACKAGES := kmod-mmc kmod-stmmac kmod-stmmac-platform kmod-usb-dwc3 kmod-usb-phy-meson-gxl kmod-usb-storage kmod-usb-storage-uas kmod-phy-realtek kmod-fs-ext4
endef
TARGET_DEVICES += b60_av21m

$(eval $(call BuildImage))
