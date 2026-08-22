# MIUI Camera 6.6 compatibility work

This directory is intentionally separate from `vendor/xiaomi/miuicamera-pearl`,
which contains the 6.1 camera integration. It is the staging area for the
6.6 camera integration and its APK patches.

## APK baseline

- Version name: `6.6.000460.0`
- Version code: `660004600`
- Package: `com.android.camera`
- Baseline APK SHA-256: `7543f1f213a1e4b106cd5aa5e4278a1719d5c5db778d2ea5c15580bc90ccc5b8`
- Staged patched APK SHA-256: `fcfec1476cd2e0e77d1e519aaa311bb28a566905e370b52c9e6d9d5ac9d8c5c5`
- Baseline APK used for verification: `/tmp/pearl-camera-test/original-6.6.apk`

The APK is a single monolithic package with ten dex files. The two patched
classes are in the primary dex and are represented by the apktool paths
`smali/S8/e.smali` and `smali/S8/d.smali`.

## Fixes

1. `S8/e.c(CaptureResult)` returns an empty `Lxi/b` when the capture result is
   null, avoiding the shutter-time crash.
2. `S8/d.f(Lxi/a;ZI)` decodes the encoded JPEG byte array with
   `BitmapFactory.decodeByteArray` before watermark processing, avoiding the
   green-image result caused by treating JPEG bytes as I420 data.

The fixes were tested in the MCP candidate APK before being recorded here.
The verified candidate was `MiuiCamera_6.6_jpeg_decode_experiment_v2.apk`; a
watermarked photograph was captured successfully and had normal colors.

The 6.6 `extract-files.sh` is deliberately not created yet, as requested.
`proprietary-files.txt` and `setup-makefiles.sh` are present so the repository
layout is ready for that later extraction step. Shared integration files from
6.1—sepolicy, configs, shims, icons, properties, and the six camera libraries—
have already been copied into this directory. The 6.1 repository itself was
not modified.

## Verification

The patches were checked against the clean primary-dex Smali extraction in:
`/run/media/admin/565d494e-b6bb-406f-9549-995c855bda33/TMP/miuicamera-6.6-two-file-verify`.
Both `git apply --check` checks matched exactly. The applied `S8/d.smali` and
`S8/e.smali` also assembled successfully with `smali assemble`; no compiler
diagnostics were produced. Runtime verification was previously performed with
the MCP candidate `MiuiCamera_6.6_jpeg_decode_experiment_v2.apk`, including a
watermarked capture with normal colors.
