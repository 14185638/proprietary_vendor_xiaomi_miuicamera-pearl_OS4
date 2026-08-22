#
# Copyright (C) 2026 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from the proprietary version
include vendor/xiaomi/miuicamera-pearl-6.6/vendor/BoardConfigVendor.mk

MIUICAMERA_PATH := vendor/xiaomi/miuicamera-pearl-6.6

# Properties
TARGET_SYSTEM_PROP += $(MIUICAMERA_PATH)/system.prop

# Sepolicy
BOARD_VENDOR_SEPOLICY_DIRS += $(MIUICAMERA_PATH)/sepolicy/vendor
