include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# ==========================================
# Phicomm B60 (av2.1.M) - S905L3B
# ==========================================
define Device/b60_av21m
  DEVICE_VENDOR := Phicomm
  DEVICE_MODEL := B60 (av2.1.M)
  DEVICE_DTS := meson-gxl-s905l3b-B60av2.1.M
  DEVICE_PACKAGES := kmod-brcmfmac wpad-basic-mbedtls kmod-usb-net kmod-usb-net-rtl8152
  KERNEL := kernel-bin | gzip | fit gzip $$(KDIR)/image-$$(DEVICE_DTS).dtb
  KERNEL_LOADADDR := 0x1080000
  KERNEL_ENTRY := 0x1080000
  UBOOT_ENTRY := 0x1080000
  IMAGES := sysupgrade.img.gz factory.img.gz
  IMAGE/sysupgrade.img.gz := boot-script | boot-img | sysupgrade-tar | gzip
  IMAGE/factory.img.gz := boot-script | boot-img | gzip
endef
TARGET_DEVICES += b60_av21m

$(eval $(call BuildImage))