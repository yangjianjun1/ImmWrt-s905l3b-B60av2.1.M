define Device/meson-gxl-s905l3b-b60-av21m
  DEVICE_VENDOR := B60
  DEVICE_MODEL := AV21M (S905L3B)
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-b60-av21m
  DEVICE_PACKAGES := kmod-dwmac-meson-gxl kmod-usb-dwc3 kmod-usb-dwc3-meson-g12a
  KERNEL_LOADADDR := 0x01080000
  KERNEL := kernel-bin | append-dtb | uImage none
  IMAGES := uImage dtb sysupgrade.tar
  IMAGE/uImage := copy
  IMAGE/dtb := copy
  IMAGE/sysupgrade.tar := sysupgrade-tar | append-metadata
  # 显式指定输出文件名（可选，让脚本好找）
  DEVICE_IMG_NAME = $$(IMG_PREFIX)-$$(1)
endef
