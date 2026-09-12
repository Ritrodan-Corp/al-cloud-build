#!/usr/bin/env bash
set -euo pipefail

ADB_TARGET="${ADB_TARGET:-127.0.0.1:5555}"
AZL_PACKAGE="com.YoStarEN.AzurLane"

section() {
  printf '\n===== %s =====\n' "$1"
}

section "Host identity and resources"
uname -a
id
df -h / /var/lib/azl-android 2>/dev/null || true
free -h || true

section "Reference ReDroid service"
systemctl is-active azl-redroid.service || true
systemctl --no-pager --full status azl-redroid.service 2>/dev/null | sed -n '1,35p' || true
systemctl cat azl-redroid.service 2>/dev/null || true

section "ADB baseline"
adb connect "$ADB_TARGET" >/dev/null 2>&1 || true
adb -s "$ADB_TARGET" wait-for-device
adb -s "$ADB_TARGET" shell getprop sys.boot_completed
printf 'ro.hardware.egl='; adb -s "$ADB_TARGET" shell getprop ro.hardware.egl
printf 'ro.hardware.vulkan='; adb -s "$ADB_TARGET" shell getprop ro.hardware.vulkan
printf 'ro.build.version.release='; adb -s "$ADB_TARGET" shell getprop ro.build.version.release
printf 'ro.product.cpu.abi='; adb -s "$ADB_TARGET" shell getprop ro.product.cpu.abi
adb -s "$ADB_TARGET" shell pm path "$AZL_PACKAGE" || true

section "Current renderer identity"
adb -s "$ADB_TARGET" shell dumpsys SurfaceFlinger 2>/dev/null \
  | grep -E -m 3 'GLES|GL_VENDOR|GL_RENDERER|GL_VERSION' || true

section "Vendor EGL inventory"
adb -s "$ADB_TARGET" shell 'ls -l /vendor/lib64/egl 2>/dev/null || true'
adb -s "$ADB_TARGET" shell 'ls -lZ /vendor/lib64/egl 2>/dev/null || true'

section "Vendor DRM/Gallium inventory"
adb -s "$ADB_TARGET" shell \
  'ls -lZ /vendor/lib64/libdrm* /vendor/lib64/egl/libgallium* 2>/dev/null || true'

section "Android linker namespace hints"
adb -s "$ADB_TARGET" shell \
  "grep -nE 'vendor/lib64|/vendor/.*/egl|namespace.*vendor|search.paths|permitted.paths' /linkerconfig/ld.config.txt 2>/dev/null | head -n 160 || true"

section "SELinux state"
adb -s "$ADB_TARGET" shell getenforce 2>/dev/null || true
adb -s "$ADB_TARGET" shell 'cat /sys/fs/selinux/enforce 2>/dev/null || true'

section "Candidate contamination check"
adb -s "$ADB_TARGET" shell \
  "find /vendor/lib64 /system/lib64 -maxdepth 3 -type f \( -iname '*mesa*' -o -iname '*gallium*' -o -iname '*llvmpipe*' \) -print 2>/dev/null | head -n 100 || true"

section "Preflight complete"
echo "READ_ONLY_PREFLIGHT_COMPLETE"
