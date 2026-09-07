# r11s LineageOS KernelSU-Next + SUSFS

Archive of the patched kernel source and build output for the Samsung
Galaxy S23 FE (codename `r11s`, SM-S711B, Exynos 2200 / S5E9925) running
LineageOS 23.2.

## Contents

- `kernel_source/` — the full ExtremeXT `android_kernel_samsung_s5e9925`
  (`lineage-23.2`) kernel tree, Linux 5.10.260, with KernelSU-Next and
  SUSFS integrated on top. Build artifacts (`out/`) are excluded — they're
  regenerable from this source.
- `anykernel3_zip/` — the final flashable AnyKernel3 zip built from this
  source, verified against your device's `vendor_boot` (see below).

## What's integrated

- **KernelSU-Next**: `pershoot/KernelSU-Next` fork, `dev-susfs` branch
  (v3.3.0-based), plus WildKernels' `static.patch` compatibility fix.
- **SUSFS**: v2.3.0, patched in via the `gki-android12-5.10` branch of
  `simonpunk/susfs4ksu` (matching this kernel's KMI generation), with two
  upstream fix commits from `pershoot/susfs4ksu` cherry-picked in.
- Kconfig: base `.config` extracted directly from your known-working
  ExtremeXT KSUN-only boot.img (via `extract-ikconfig`) to minimize
  unrelated drift, with `CONFIG_KSU`, `CONFIG_KSU_SUSFS` and its
  sub-options, overlay/tmpfs support enabled on top.

## Key issue found and fixed

The kernel build initially panicked on boot with:
```
usb_notify_layer: Unknown symbol usb_disable_autosuspend (err -2)
init: Failed to load kernel modules
Kernel panic - not syncing: Attempted to kill init!
```

Root cause: `CONFIG_TRIM_UNUSED_KSYMS` was silently stripping the
`__ksymtab` export entry for `usb_disable_autosuspend` (a CRC record
survived, but the actual symbol-lookup entry `insmod` needs did not)
because `usb_notify_layer.ko` — a proprietary Samsung blob shipped in
`vendor_boot`, outside this open-source kernel tree — was invisible to
the trimmer's "what's actually used" analysis.

Fix: `CONFIG_TRIM_UNUSED_KSYMS` disabled entirely, keeping every
`EXPORT_SYMBOL`/`EXPORT_SYMBOL_GPL` regardless of whether this build's
own module list references it.

Validated by extracting all 324 `.ko` files from the real `vendor_boot`
ramdisk and checking every required symbol's CRC *and* ksymtab presence
against this build's `vmlinux` — zero mismatches, zero silently-missing
exports.

`vendor_boot` itself is never modified — only the `boot` partition
(kernel `Image`) is replaced by the AnyKernel3 zip.
