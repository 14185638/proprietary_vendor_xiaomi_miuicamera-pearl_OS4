# MIUI Camera 6.6 compatibility work

This directory is intentionally separate from `vendor/xiaomi/miuicamera-pearl`,
which contains the 6.1 camera integration. It is the staging area for the
6.6 camera integration and its APK patches.

## APK baseline

- Version name: `6.6.000460.0`
- Version code: `660004600`
- Package: `com.android.camera`
- Baseline APK SHA-256: `7543f1f213a1e4b106cd5aa5e4278a1719d5c5db778d2ea5c15580bc90ccc5b8`
- Staged patched APK SHA-256: `41733922bf6624443c23bb3edd57344b95f43b41172ac6a9ade0434cf4583a41`
- Baseline APK used for verification: `/tmp/pearl-camera-test/original-6.6.apk`

The APK is a single monolithic package with ten dex files. Patched smali is
represented by apktool paths such as `smali/S8/e.smali`, `smali/S8/d.smali`,
and `smali_classes3/If/a.smali`.

## Fixes

1. `S8/e.c(CaptureResult)` returns an empty `Lxi/b` when the capture result is
   null, avoiding the shutter-time crash.
2. `S8/d.f(Lxi/a;ZI)` decodes the encoded JPEG byte array with
   `BitmapFactory.decodeByteArray` before watermark processing, avoiding the
   green-image result caused by treating JPEG bytes as I420 data.
3. `If.a.c` catches `FileNotFoundException` when an `obfu_res/...` drawable is
   missing and falls back to normal `Resources.getDrawable(resourceId)`,
   fixing the camera main-interface crash when the top menu arrow is tapped.

The fixes were tested in the MCP candidate APK before being recorded here.
The verified candidate was `MiuiCamera_6.6_jpeg_decode_experiment_v2.apk`; a
watermarked photograph was captured successfully and had normal colors.

The 6.6 `extract-files.sh` applies the patches under `miui-camera-patches/`
during extraction. Shared integration files from 6.1—sepolicy, configs, shims,
icons, properties, and the six camera libraries—have also been copied into this
directory. The 6.1 repository itself was not modified.

## Verification

The patches were checked against the clean primary-dex Smali extraction in:
`/run/media/admin/565d494e-b6bb-406f-9549-995c855bda33/TMP/miuicamera-6.6-two-file-verify`.
Both `git apply --check` checks matched exactly. The applied `S8/d.smali` and
`S8/e.smali` also assembled successfully with `smali assemble`; no compiler
diagnostics were produced. Runtime verification was previously performed with
the MCP candidate `MiuiCamera_6.6_jpeg_decode_experiment_v2.apk`, including a
watermarked capture with normal colors.
