#!/bin/sh
# SPDX-License-Identifier: GPL-2.0-or-later

RAMFS_COPY_BIN='fw_printenv fw_setenv'
RAMFS_COPY_DATA='/etc/fw_env.config /var/lock/fw_printenv.lock'
REQUIRE_IMAGE_METADATA=1

platform_check_image() {
	case "$(board_name)" in
	hardkernel,odroid-c2)
		legacy_sdcard_check_image "$1"
		;;
	amlogic,m302a|\
	amlogic,s905l3b)
		return 0
		;;
	*)
		return 0
		;;
	esac
}

platform_do_upgrade() {
	case "$(board_name)" in
	hardkernel,odroid-c2)
		legacy_sdcard_do_upgrade "$1"
		;;
	amlogic,m302a|\
	amlogic,s905l3b)
		default_do_upgrade "$1"
		;;
	*)
		default_do_upgrade "$1"
		;;
	esac
}

platform_copy_config() {
	case "$(board_name)" in
	hardkernel,odroid-c2)
		legacy_sdcard_copy_config
		;;
	amlogic,m302a|\
	amlogic,s905l3b)
		local partdev
		. /lib/upgrade/common.sh
		if export_bootdevice && export_partdevice partdev 1; then
			mkdir -p /boot
			if mount -t vfat -o rw,noatime "/dev/$partdev" /boot; then
				cp -f /sysupgrade.tgz /boot/
				umount /boot
			else
				echo "Failed to mount boot partition, config not saved!"
			fi
		fi
		;;
	esac
}