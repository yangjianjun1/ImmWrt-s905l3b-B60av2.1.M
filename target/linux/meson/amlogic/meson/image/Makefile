#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

FAT32_BLOCK_SIZE=1024
FAT32_BLOCKS=$(shell echo $$(($(CONFIG_TARGET_KERNEL_PARTSIZE)*1024 * 1024/$(FAT32_BLOCK_SIZE))))

define Build/boot-script
	# Make an U-boot image and copy it to the boot partition
	mkimage -A arm64 -O linux -T script -C none -a 0 -e 0 -n "boot.scr" -d boot.cmd $(KDIR)/boot.scr
endef

define Build/emmc-common
	$(RM) -f $@.boot
	mkfs.fat -C $@.boot $(FAT32_BLOCKS)

	mkdir -p $(KDIR)/boot.fat

	$(CP) $(KDIR)/boot.scr $(KDIR)/boot.fat/boot.scr
	mcopy -i $@.boot $(KDIR)/boot.scr ::
	$(CP) $(KDIR)/boot.fat/boot.scr $(KDIR)/boot.scr

	$(CP) $(IMAGE_KERNEL) $(KDIR)/boot.fat/uImage
	mcopy -i $@.boot $(KDIR)/boot.fat/uImage ::

	$(foreach dts,$(shell echo $(DEVICE_DTS)),$(CP) $(DTS_DIR)/$(dts).dtb $(KDIR)/boot.fat/dtb;)
	mcopy -i $@.boot $(KDIR)/boot.fat/dtb ::

	$(RM) -rf $(KDIR)/boot.fat

	./gen_aml_emmc_img.sh $@ $@.boot $(IMAGE_ROOTFS) \
		$(CONFIG_TARGET_KERNEL_PARTSIZE) $(CONFIG_TARGET_ROOTFS_PARTSIZE)
endef

### Devices ###
define Device/Default
  FILESYSTEMS := squashfs ext4
  IMAGES := emmc.img
  KERNEL_DEPENDS = $$(wildcard $(DTS_DIR)/$$(DEVICE_DTS).dts)
  KERNEL_LOADADDR := 0x00208000
  KERNEL_NAME := Image
  KERNEL := kernel-bin | uImage none
  PROFILES = Default $$(DEVICE_NAME)
endef

define Device/s905l3b-b60
  DEVICE_DTS := amlogic/meson-gxl-s905l3b-B60av2.1.M
  DEVICE_TITLE := B60 av2.1.M (S905L3B)
  KERNEL_LOADADDR := 0x00208000
  IMAGE/emmc.img := boot-script | emmc-common
endef

ifeq ($(SUBTARGET),s905l3b)
  TARGET_DEVICES += s905l3b-b60
endif

$(eval $(call BuildImage))