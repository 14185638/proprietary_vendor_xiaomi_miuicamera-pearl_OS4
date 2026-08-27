# MIUI Camera 6.6 compatibility work

This directory is intentionally separate from `vendor/xiaomi/miuicamera-pearl`,
which contains the 6.1 camera integration. It is the staging area for the
6.6 camera integration and its APK patches.

## APK baseline

- Version name: `6.6.000460.0`
- Version code: `660004600`
- Package: `com.android.camera`
- Baseline APK SHA-256: `7543f1f213a1e4b106cd5aa5e4278a1719d5c5db778d2ea5c15580bc90ccc5b8`
- Staged patched APK SHA-256: `6340a5445cc8d170d8e35606eb34756e482b743248c33422e4095a38611df43c`
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
4. `j9.i0.D(String, boolean, boolean, boolean)` always enqueues the main shot
   save path even on non-parallel capture, and `xm.b$a.run()` backfills
   `StorageData.imageName` from the save path. This fixes LiveShot/dynamic
   photo on pearl where non-parallel capture previously left
   `ParallelTaskData.savePath` null and the video clip save crashed, so only a
   normal still was produced.
5. `z4.G.b(...)` hides the camera switch container (`v9_capture_picker_layout`)
   when the current mode is portrait (`0xab`), and restores it for other modes.
   This removes the front/back camera switch key in portrait mode.
6. `H4.f0.provideAnimateElement(...)` hides the zoom toggle container when the
   current mode is normal photo (`0xa3`) and the front camera is active, and
   restores it for the rear camera. This matches stock behavior where the
   front camera does not show zoom ratio buttons in normal photo mode.
7. The squashed `0023` patch enables document mode end-to-end on pearl, enables
   night mode with ultra-wide support, and disables slow motion to avoid the
   unsupported HAL path crashing.

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

The LiveShot/dynamic-photo fix was verified on pearl with the MCP candidate
`camera_fixed.apk`: with dynamic photo enabled, a capture produced
`/storage/emulated/0/DCIM/Camera/MVIMG_20260827_182800.jpg` with a non-empty
embedded video clip instead of a plain still.

The portrait camera-switch removal and front-camera zoom-toggle removal were
verified on pearl with `camera_fixed_zoom6.apk`: portrait mode no longer shows
the front/back switch, and normal photo mode hides the zoom ratio buttons on
the front camera while keeping them on the rear camera.

## Privacy / ad-tracking removal

The staged APK has been cleaned of the active ad/tracking paths:

- Removed `com.google.android.gms.permission.AD_ID`.
- Removed `android.permission.READ_PHONE_STATE`.
- Disabled and stripped Xiaomi OneTrack (`com.xiaomi.onetrack.*`), including
  OAID/GAID/Android ID collection and `doGetAdMonitor`.
- Disabled the Google Advertising ID client (`com.google.android.gms.internal.ads_identifier.*`,
  obfuscated `Zc/*`) and stopped CloudConfig from reading GAID.
- Removed `com.miui.analytics.*` AIDL stubs.

Verified on pearl: camera launches, no fatal/verify errors observed in the
test build before this repository update.
