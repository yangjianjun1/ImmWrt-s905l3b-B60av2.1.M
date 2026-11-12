#
# B60 AV21M (M302A / S905L3B) device definition
#

BUILD_DATE := $(shell date +%Y%m%d)

define Device/meson-gxl-s905l3b-b60-av21m
  DEVICE_VENDOR := B60
  DEVICE_MODEL := AV21M (S905L3B)
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-b60-av21m
  DEVICE_DTS_DIR := $(DTS_DIR)

  KERNEL := kernel-bin
  KERNEL_NAME := Image
  KERNEL_LOADADDR := 0x1080000

  IMAGES := $(BUILD_DATE)-sysupgrade.img.gz $(BUILD_DATE)-usb-boot.img.gz
  IMAGE/$(BUILD_DATE)-sysupgrade.img.gz := boot-script | aml-img | gzip
  IMAGE/$(BUILD_DATE)-usb-boot.img.gz := boot-script | aml-img | gzip

  DEVICE_PACKAGES := \
    kmod-mmc \
    kmod-sdhci \
    kmod-sdhci-of-arasan \
    kmod-dwmac-meson-gxl \
    kmod-amlogic-phy \
    kmod-libphy \
    kmod-usb-dwc3 \
    kmod-usb2 \
    kmod-usb-ohci \
    kmod-usb-ehci \
    kmod-gpio-button-hotplug \
    uboot-envtools \
    block-mount

  SUPPORTED_DEVICES := s905l3b-b60-av21m
endef
TARGET_DEVICES += meson-gxl-s905l3b-b60-av21m