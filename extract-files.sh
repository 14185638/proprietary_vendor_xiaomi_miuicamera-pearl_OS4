#!/bin/bash
#
# SPDX-FileCopyrightText: 2016 The CyanogenMod Project
# SPDX-FileCopyrightText: 2017-2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=vendor
VENDOR=xiaomi/miuicamera-pearl-6.6

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

export TARGET_ENABLE_CHECKELF=true

# If XML files don't have comments before the XML header, use this flag.
# Can still be used with broken XML files by using blob_fixup.
export TARGET_DISABLE_XML_FIXING=true

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction.
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        system/priv-app/MiuiCamera/MiuiCamera.apk)
            [ "$2" = "" ] && return 0

            local apktool="${ANDROID_ROOT}/prebuilts/extract-tools/common/apktool/apktool.jar"
            local apk_dir
            apk_dir="$(mktemp -d)"

            java -jar "${apktool}" d -f -o "${apk_dir}" "${2}"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0001-Drop-null-capture-result.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0002-Decode-jpeg-before-watermark.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0003-immersive-system-bars-for-camera-settings.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0004-extend-settings-content-behind-navigation-bar.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0005-immersive-system-bars-on-description-activity.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0006-Restore-beauty-fallback-for-unknown-types.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0007-Restore-beauty-items-for-shine-types.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0008-Fix-portrait-front-bokeh-capture-and-jpeg-orientation.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0009-ultrawide-macro-portrait-hide.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0010-remove-idphoto.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0011-fix-watermark-model.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0012-unlock-4k60.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0013-shutter-4000.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0014-enable-video-prompter.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0015-prompter-edit-immersive.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0016-Portrait-thumbnail-loading-animation.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0017-Portrait-thumbnail-loading-finish.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0018-Fix-wechat-intent-capture-verifyerror.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0019-Fix-obfu-res-missing-drawable-crash.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0020-fix-liveshot-nonparallel-savepath.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0021-remove-portrait-camera-switch.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0022-hide-front-camera-zoom-toggle.patch"
            patch -d "${apk_dir}" -p1 < "${MY_DIR}/miui-camera-patches/0023-enable-document-night-disable-slowmotion.patch"
            java -jar "${apktool}" b "${apk_dir}" -o "${2}"

            # The 6.6 resource table maps the icon to obfuscated WebP paths.
            # Replace their payloads after apktool rebuild so aapt2 does not
            # try to parse the PNG files as WebP resources.
            cp "${MY_DIR}/icon/mipmap-xhdpi/f9l.png" "${apk_dir}/res/znu.webp"
            cp "${MY_DIR}/icon/mipmap-xxhdpi/f9l.png" "${apk_dir}/res/Mc7.webp"
            cp "${MY_DIR}/icon/mipmap-xxxhdpi/f9l.png" "${apk_dir}/res/9eM.webp"
            (cd "${apk_dir}" && zip -q -0 -u "${2}" res/znu.webp res/Mc7.webp res/9eM.webp)

            rm -rf "${apk_dir}"
            ;;

        system/lib64/libcamera_algoup_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            grep -q "libgui_shim_miuicamera.so" "${2}" || \
                "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            "${SIGSCAN}" -p "08 AD 40 F9" -P "08 A9 40 f9" -f "${2}"
            ;;

        system/lib64/libcamera_mianode_jni.xiaomi.so|\
        system/lib64/libcamera_ispinterface_jni.xiaomi.so)
            [ "$2" = "" ] && return 0
            grep -q "libgui_shim_miuicamera.so" "${2}" || \
                "${PATCHELF}" --add-needed "libgui_shim_miuicamera.so" "${2}"
            ;;

        system/lib64/vendor.mediatek.hardware.camera.isphal-V1-ndk.so)
            [ "$2" = "" ] && return 0
            "${PATCHELF}" --replace-needed \
                "android.hardware.graphics.common-V5-ndk.so" \
                "android.hardware.graphics.common-V7-ndk.so" "${2}"
            ;;

        *)
            return 1
            ;;
    esac

    return 0
}

function blob_fixup_dry() {
    blob_fixup "$1" ""
}

# Initialize the helper. This script intentionally owns the 6.6 namespace.
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
