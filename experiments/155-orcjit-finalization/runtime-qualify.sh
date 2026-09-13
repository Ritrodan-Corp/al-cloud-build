#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-}"
case "$MODE" in probe|game) ;; *) echo "usage: $0 probe|game" >&2; exit 2 ;; esac

ROOT=/home/ritrodano2/exp155
C="$ROOT/candidate/exp155-mesa-arm64-deploy/payload/lib"
AUDIT="$ROOT/candidate/exp155-mesa-arm64-deploy/audit"
GPU=/home/ritrodano2/gate2/gpu_config_gate2.sh
PROBE_APK=/home/ritrodano2/gate2/probe-artifact/app-debug.apk
ADB=127.0.0.1:5555
REF_DATA=/var/lib/azl-android/data
PROBE_DATA=/var/lib/azl-android/exp155-probe-data-1
GAME_DATA=/var/lib/azl-android/exp155-game-data-1
E="$ROOT/evidence"
PKG=com.YoStarEN.AzurLane
ACT=com.manjuu.azurlane.PrePermissionActivity
mkdir -p "$E"

candidate_hash() { sha256sum "$C/libgallium_dri.so" | awk '{print $1}'; }

restore_reference() {
  set +e
  adb -s "$ADB" shell am force-stop "$PKG" >/dev/null 2>&1 || true
  sudo -n docker rm -f azl-redroid-exp155-probe azl-redroid-exp155-game >/dev/null 2>&1 || true
  sudo -n systemctl reset-failed azl-redroid.service >/dev/null 2>&1 || true
  sudo -n systemctl start azl-redroid.service >/dev/null 2>&1 || true
  adb disconnect "$ADB" >/dev/null 2>&1 || true
  boot=''
  for i in $(seq 1 60); do
    adb connect "$ADB" >/dev/null 2>&1 || true
    boot=$(adb -s "$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
    [[ "$boot" == 1 ]] && break
    sleep 2
  done
  service_state="$(systemctl is-active azl-redroid.service 2>/dev/null || true)"
  egl_state="$(adb -s "$ADB" shell getprop ro.hardware.egl 2>/dev/null | tr -d '\r' || true)"
  vk_state="$(adb -s "$ADB" shell getprop ro.hardware.vulkan 2>/dev/null | tr -d '\r' || true)"
  printf 'RESTORE service=%s boot=%s egl=%s vulkan=%s\n' \
    "$service_state" "${boot:-}" "$egl_state" "$vk_state" | tee "$E/restore-audit.txt"
  [[ "$service_state" == active && "${boot:-}" == 1 && "$egl_state" == angle && "$vk_state" == pastel ]]
}
trap restore_reference EXIT

verify_candidate() {
  for f in libEGL.so libGLESv1_CM.so libGLESv2.so libdrm.so libgallium_dri.so; do
    test -f "$C/$f"
    exp=$(awk -v n="/$f" '$2 ~ n"$" {print $1; exit}' "$AUDIT/payload.sha256")
    act=$(sha256sum "$C/$f" | awk '{print $1}')
    [[ -n "$exp" && "$act" == "$exp" ]] || { echo "hash mismatch: $f" >&2; exit 1; }
  done
  grep -q 'ALCLOUD_ORC_FINALIZATION' "$AUDIT/instrumentation-binary-proof.txt"
}

boot_candidate() {
  local name=$1 data=$2
  sudo -n docker rm -f "$name" >/dev/null 2>&1 || true
  sudo -n docker run -d --name "$name" --privileged \
    -v /dev/binderfs/binder:/dev/binder -v /dev/binderfs/hwbinder:/dev/hwbinder -v /dev/binderfs/vndbinder:/dev/vndbinder \
    -p 127.0.0.1:5555:5555 -v "$data:/data" \
    -v "$GPU:/vendor/bin/gpu_config.sh:ro" \
    -v "$C/libEGL.so:/vendor/lib64/egl/libEGL_mesa.so:ro" \
    -v "$C/libGLESv1_CM.so:/vendor/lib64/egl/libGLESv1_CM_mesa.so:ro" \
    -v "$C/libGLESv2.so:/vendor/lib64/egl/libGLESv2_mesa.so:ro" \
    -v "$C/libgallium_dri.so:/vendor/lib64/libgallium_dri.so:ro" \
    -v "$C/libdrm.so:/vendor/lib64/libdrm.so:ro" \
    -e MESA_ANDROID_NO_KMS_SWRAST=1 -e GALLIUM_DRIVER=llvmpipe \
    azl-redroid:14.0.0_64only-litegapps \
    androidboot.redroid_gpu_mode=guest androidboot.use_memfd=true androidboot.redroid_width=1280 androidboot.redroid_height=720
  adb disconnect "$ADB" >/dev/null 2>&1 || true
  local boot=''
  for i in $(seq 1 60); do
    adb connect "$ADB" >/dev/null 2>&1 || true
    boot=$(adb -s "$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r' || true)
    [[ "$boot" == 1 ]] && break
    sleep 2
  done
  [[ "$boot" == 1 ]]
  [[ "$(adb -s "$ADB" shell getprop ro.hardware.egl | tr -d '\r')" == mesa ]]
  adb -s "$ADB" shell dumpsys SurfaceFlinger 2>/dev/null | grep -q 'Mesa, llvmpipe (LLVM 19.1.7'
}

verify_candidate
BASE_APK=$(adb -s "$ADB" shell pm path "$PKG" 2>/dev/null | sed -n 's/^package://p' | head -1 || true)
BASE_APK_SHA=''
if [[ -n "$BASE_APK" ]]; then BASE_APK_SHA=$(adb -s "$ADB" shell sha256sum "$BASE_APK" 2>/dev/null | awk '{print $1}' || true); fi

if [[ "$MODE" == probe ]]; then
  echo '=== Experiment 155 presentation regression ==='
  sudo -n systemctl stop azl-redroid.service || true
  sudo -n rm -rf "$PROBE_DATA"
  sudo -n mkdir -p "$PROBE_DATA"
  sudo -n chmod 0777 "$PROBE_DATA"
  boot_candidate azl-redroid-exp155-probe "$PROBE_DATA"
  adb -s "$ADB" install -r "$PROBE_APK"
  adb -s "$ADB" logcat -c
  adb -s "$ADB" shell am start -W -n com.ritrodan.alcloud.gate2probe/.MainActivity
  sleep 45
  P0=$(adb -s "$ADB" shell pidof com.ritrodan.alcloud.gate2probe | tr -d '\r')
  test -n "$P0"
  adb -s "$ADB" logcat -d -v threadtime > "$E/probe-logcat.txt"
  grep -E 'ALCLOUD_ORC_FINALIZATION|ALCLOUD_FINALIZE' "$E/probe-logcat.txt" > "$E/probe-finalization-markers.txt"
  test -s "$E/probe-finalization-markers.txt"
  if grep -E 'ALCLOUD_GLES_PROBE:.*gl_error=0x[1-9a-fA-F]' "$E/probe-logcat.txt"; then exit 1; fi
  adb -s "$ADB" shell wm size 1024x576
  sleep 15
  [[ "$(adb -s "$ADB" shell pidof com.ritrodan.alcloud.gate2probe | tr -d '\r')" == "$P0" ]]
  adb -s "$ADB" exec-out screencap -p > "$E/probe-resized.png"
  adb -s "$ADB" shell wm size reset
  sleep 15
  [[ "$(adb -s "$ADB" shell pidof com.ritrodan.alcloud.gate2probe | tr -d '\r')" == "$P0" ]]
  adb -s "$ADB" exec-out screencap -p > "$E/probe-reset.png"
  for i in $(seq 1 17); do
    sleep 30
    [[ "$(adb -s "$ADB" shell pidof com.ritrodan.alcloud.gate2probe | tr -d '\r')" == "$P0" ]]
  done
  adb -s "$ADB" logcat -d -v threadtime > "$E/probe-final-logcat.txt"
  grep -E 'ALCLOUD_ORC_FINALIZATION|ALCLOUD_FINALIZE' "$E/probe-final-logcat.txt" > "$E/probe-final-finalization-markers.txt"
  if grep -E 'ALCLOUD_GLES_PROBE:.*gl_error=0x[1-9a-fA-F]|Fatal signal.*gate2probe|FATAL EXCEPTION.*gate2probe' "$E/probe-final-logcat.txt"; then exit 1; fi
  adb -s "$ADB" exec-out screencap -p > "$E/probe-final.png"
  GALLIUM_HASH=$(candidate_hash)
  printf 'PASS\nlibgallium_sha256=%s\nprobe_pid=%s\n' "$GALLIUM_HASH" "$P0" > "$E/probe-pass.txt"
  sha256sum "$E"/probe-*.txt "$E"/probe-*.png 2>/dev/null > "$E/probe-evidence.sha256" || true
  echo 'PROBE_PASS'
  exit 0
fi

# Game mode requires a presentation pass for this exact candidate.
test -s "$E/probe-pass.txt"
GALLIUM_HASH=$(candidate_hash)
grep -qx "libgallium_sha256=$GALLIUM_HASH" "$E/probe-pass.txt"

echo '=== Experiment 155 one-launch game diagnostic ==='
sudo -n systemctl stop azl-redroid.service || true
sudo -n rm -rf "$GAME_DATA"
sudo -n mkdir -p "$GAME_DATA"
sudo -n rsync -aHAX --numeric-ids --delete "$REF_DATA/" "$GAME_DATA/"
SRC_APK=$(sudo -n find "$REF_DATA/app" -type f -path '*com.YoStarEN.AzurLane*' -name base.apk -print -quit)
DST_APK=${SRC_APK/$REF_DATA/$GAME_DATA}
[[ "$(sudo -n sha256sum "$SRC_APK" | awk '{print $1}')" == "$(sudo -n sha256sum "$DST_APK" | awk '{print $1}')" ]]
[[ "$(sudo -n stat -c %i "$SRC_APK")" != "$(sudo -n stat -c %i "$DST_APK")" ]]
boot_candidate azl-redroid-exp155-game "$GAME_DATA"
adb -s "$ADB" shell am force-stop "$PKG" || true
adb -s "$ADB" logcat -c
adb -s "$ADB" logcat -b crash -c || true
adb -s "$ADB" logcat -b events -c || true
adb -s "$ADB" root >/dev/null 2>&1 || true
sleep 1
adb -s "$ADB" shell 'ls -1 /data/tombstones 2>/dev/null' > "$E/game-tombstones-before.txt" || true
printf 'launch_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$E/game-result.txt"
adb -s "$ADB" shell am start -W -n "$PKG/$ACT" | tee -a "$E/game-result.txt"
: > "$E/game-pid-timeline.txt"
: > "$E/game-maps.txt"
STOP_SEQUENCE_SEEN=0
for i in $(seq 1 200); do
  PID_NOW="$(adb -s "$ADB" shell pidof "$PKG" 2>/dev/null | tr -d '\r' | awk '{print $1}' || true)"
  printf '%03d %s\n' "$i" "$PID_NOW" >> "$E/game-pid-timeline.txt"
  if [[ -n "$PID_NOW" ]]; then
    {
      printf '=== sample=%03d pid=%s ===\n' "$i" "$PID_NOW"
      adb -s "$ADB" shell "cat /proc/$PID_NOW/maps 2>/dev/null" || true
    } >> "$E/game-maps.txt"
  fi
  adb -s "$ADB" logcat -d -v threadtime > "$E/game-live-logcat.txt"
  if grep -q 'ALCLOUD_FINALIZE.*LPJIT_EXIT_CONTEXT_' "$E/game-live-logcat.txt"; then
    STOP_SEQUENCE_SEEN=1
    break
  fi
  sleep 0.1
done
adb -s "$ADB" exec-out screencap -p > "$E/game-first-finalization.png" || true
adb -s "$ADB" shell am force-stop "$PKG" || true
sleep 1
adb -s "$ADB" logcat -d -v threadtime > "$E/game-logcat.txt"
adb -s "$ADB" logcat -d -b crash -v threadtime > "$E/game-crash.txt" || true
adb -s "$ADB" logcat -d -b events -v threadtime > "$E/game-events.txt" || true
adb -s "$ADB" shell dumpsys activity processes > "$E/game-activity-processes.txt" || true
sudo -n docker inspect azl-redroid-exp155-game > "$E/game-container-inspect.json" 2>/dev/null || true
grep -E 'ALCLOUD_ORC_FINALIZATION|ALCLOUD_FINALIZE' "$E/game-logcat.txt" > "$E/game-finalization-markers.txt" || true
grep -E 'UnityGfxDeviceW|gallivm_add_global_mapping|ALCLOUD_ORC_FINALIZATION|ALCLOUD_FINALIZE|Fatal signal|FORTIFY|SIGSEGV|SIGABRT|libgallium_dri' "$E/game-logcat.txt" > "$E/game-decisive-markers.txt" || true
python3 - "$E/game-finalization-markers.txt" "$E/game-classification.txt" <<'PY'
import re
import sys
source, destination = sys.argv[1:3]
event_re = re.compile(r'pid=(\d+)\s+tid=(\d+)\s+event=(\S+)\s+corr=(\d+).*?arg=(\S+).*?match=(\d+)')
wrap, dso_context, process_other, bad_wrap = set(), [], [], []
for line in open(source, errors='replace'):
    m = event_re.search(line)
    if not m:
        continue
    pid, tid, event, corr, arg, match = m.groups()
    key = (pid, tid, corr)
    if event == 'FINALIZE_WRAP_BEGIN':
        if match == '1':
            wrap.add(key)
        elif arg not in {'(nil)', '0x0'}:
            bad_wrap.append((key, arg))
    elif event == 'LPJIT_EXIT_CONTEXT_DSO':
        dso_context.append(key)
    elif event == 'LPJIT_EXIT_CONTEXT_PROCESS_OR_OTHER':
        process_other.append(key)
paired = [key for key in dso_context if key in wrap]
if bad_wrap:
    classification = 'INSTRUMENTATION_FAIL_NONMATCHING_FINALIZE_ARG'
elif paired:
    classification = 'DSO_SPECIFIC_FINALIZATION_CONFIRMED'
elif process_other:
    classification = 'PROCESS_OR_OTHER_CAPTURED_INCONCLUSIVE'
else:
    classification = 'NO_CLASSIFIABLE_FINALIZATION_CONTEXT'
with open(destination, 'w') as out:
    out.write(f'classification={classification}\n')
    out.write(f'matching_wrap_context_pairs={len(paired)}\n')
    out.write(f'process_or_other_contexts={len(process_other)}\n')
    out.write(f'nonmatching_nonnull_wraps={len(bad_wrap)}\n')
print(classification)
if bad_wrap:
    raise SystemExit(2)
PY
printf 'stop_sequence_seen=%s\n' "$STOP_SEQUENCE_SEEN" >> "$E/game-result.txt"
cat "$E/game-classification.txt" >> "$E/game-result.txt"
test "$STOP_SEQUENCE_SEEN" -eq 1
adb -s "$ADB" root >/dev/null 2>&1 || true
sleep 1
adb -s "$ADB" shell 'ls -lt /data/tombstones 2>/dev/null | head -n 20' > "$E/game-tombstones.txt" || true
adb -s "$ADB" shell 'for f in $(ls -t /data/tombstones/tombstone_* 2>/dev/null | head -n 3); do echo "=== $f ==="; cat "$f"; done' > "$E/game-tombstone-contents.txt" || true
adb -s "$ADB" shell am force-stop "$PKG" || true
sha256sum "$E"/game-*.txt "$E"/game-*.png 2>/dev/null > "$E/game-evidence.sha256" || true

echo 'GAME_DIAGNOSTIC_CAPTURED'
