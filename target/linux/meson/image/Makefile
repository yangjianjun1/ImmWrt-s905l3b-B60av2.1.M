# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) 2024 OpenWrt.org

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/image.mk

# 引入设备定义（用当前 Makefile 所在目录）
include $(dir $(lastword $(MAKEFILE_LIST)))/b60av21m.mk

$(eval $(call BuildImage))
