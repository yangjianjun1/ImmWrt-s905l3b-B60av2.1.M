#
# B60 AV21M (M302A / S905L3B) device definition
#

define Device/meson-gxl-s905l3b-b60-av21m
  DEVICE_VENDOR := B60
  DEVICE_MODEL := AV21M (S905L3B)
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-b60-av21m

  KERNEL := kernel-bin | gzip | uImage none
  KERNEL_NAME := Image
  KERNEL_LOADADDR := 0x01080000

  IMAGES := sysupgrade.tar
  IMAGE/sysupgrade.tar := sysupgrade-tar

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
    block-mount \
    kmod-fs-btrfs \
    btrfs-progs

  SUPPORTED_DEVICES := amlogic,meson-gxl-s905l3b-b60-av21m
endef
TARGET_DEVICES += meson-gxl-s905l3b-b60-av21m