# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2006-2013 OpenWrt.org

ARCH:=aarch64
SUBTARGET:=s905l3b
BOARDNAME:=Amlogic S905L3B boards (64 bit)
CPU_TYPE:=cortex-a53

define Target/Description
	Build firmware image for Amlogic S905L3B SoC devices.
	This firmware features a 64 bit kernel.
endef