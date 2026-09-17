#!/bin/bash
set -Eeuo pipefail

C=alcloud-redroid-smoke
DATA=/var/lib/alcloud-redroid/data
LAUNCHER=/home/ubuntu/alcloud-start-redroid-smoke.sh
LOG=/home/ubuntu/alcloud-switch-redroid-fps.log
TARGET_FPS=${1:-}
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OLD=
CURRENT_FPS=
NEW_STARTED=0
RENAMED=0

exec > >(tee -a "$LOG") 2>&1
printf '\n[%s] fps switch target=%s\n' "$(date -u +%FT%TZ)" "$TARGET_FPS"

[ "$(id -u)" -eq 0 ] || { echo 'ERROR: root required'; exit 2; }
case "$TARGET_FPS" in 30|60) ;; *) echo 'ERROR: target FPS must be 30 or 60'; exit 3;; esac
[ -d "$DATA" ] && [ -d "$DATA/media" ] || { echo "ERROR: persistent data missing/incomplete: $DATA"; exit 4; }
docker inspect "$C" >/dev/null 2>&1 || { echo "ERROR: container $C not found"; exit 5; }
[ "$(docker inspect -f '{{.State.Running}}' "$C")" = true ] || { echo "ERROR: $C not running"; exit 6; }

MOUNT=$(docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}}|{{.Source}}|{{.Destination}}{{end}}{{end}}')
[ "$MOUNT" = "bind|$DATA|/data" ] || { echo "ERROR: unexpected /data mount: $MOUNT"; exit 7; }
CURRENT_FPS=$(docker inspect "$C" --format '{{join .Config.Cmd "\n"}}' | sed -n 's/^androidboot.redroid_fps=//p' | tail -1)
case "$CURRENT_FPS" in 30|60) ;; *) echo "ERROR: cannot resolve current FPS from container: $CURRENT_FPS"; exit 8;; esac
if [ "$CURRENT_FPS" = "$TARGET_FPS" ]; then
  echo "ALREADY_AT_TARGET current_fps=$CURRENT_FPS"
  exit 0
fi
OLD="${C}-fps${CURRENT_FPS}-pre-${STAMP}"

echo "current_fps=$CURRENT_FPS target_fps=$TARGET_FPS"
echo "data_mount=$MOUNT"
echo "data_bytes=$(du -sb "$DATA" | awk '{print $1}')"
echo "game_kib=$(du -sk "$DATA/media/0/Android/data/com.YoStarEN.AzurLane" 2>/dev/null | awk '{print $1}')"

docker inspect "$C" > "/home/ubuntu/alcloud-redroid-fps${CURRENT_FPS}-inspect-${STAMP}.json"
chown ubuntu:ubuntu "/home/ubuntu/alcloud-redroid-fps${CURRENT_FPS}-inspect-${STAMP}.json"

rollback() {
  rc=$?
  [ "$rc" -eq 0 ] && return
  trap - ERR
  echo "[$(date -u +%FT%TZ)] ERROR rc=$rc; rollback beginning"
  if [ "$NEW_STARTED" -eq 1 ]; then docker rm -f "$C" >/dev/null 2>&1 || true; fi
  if [ "$RENAMED" -eq 1 ]; then
    docker rename "$OLD" "$C" >/dev/null 2>&1 || true
    docker start "$C" >/dev/null 2>&1 || true
  fi
  echo "[$(date -u +%FT%TZ)] rollback attempted"
  exit "$rc"
}
trap rollback ERR

# Quiesce guest writes before changing containers.
docker exec "$C" sh -c 'am force-stop com.YoStarEN.AzurLane >/dev/null 2>&1 || true; sync'
docker stop -t 30 "$C" >/dev/null
docker rename "$C" "$OLD"
RENAMED=1

NEW_ID=$(docker run -d --name "$C" --privileged \
  --mount type=bind,src="$DATA",dst=/data \
  -v /dev/binderfs/binder:/dev/binder \
  -v /dev/binderfs/hwbinder:/dev/hwbinder \
  -v /dev/binderfs/vndbinder:/dev/vndbinder \
  -p 127.0.0.1:5555:5555 \
  redroid/redroid:14.0.0_64only-latest \
  androidboot.redroid_gpu_mode=guest \
  androidboot.use_memfd=true \
  androidboot.redroid_width=1280 \
  androidboot.redroid_height=720 \
  androidboot.redroid_fps="$TARGET_FPS")
NEW_STARTED=1
echo "new_container_id=$NEW_ID"

BOOT=0
for _ in $(seq 1 120); do
  if [ "$(docker exec "$C" getprop sys.boot_completed 2>/dev/null || true)" = 1 ]; then BOOT=1; break; fi
  sleep 1
done
[ "$BOOT" -eq 1 ] || { echo 'ERROR: Android boot timeout'; false; }

docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}}|{{.Source}}|{{.Destination}}{{end}}{{end}}' | grep -Fx "bind|$DATA|/data"
docker exec "$C" pm path com.YoStarEN.AzurLane | grep -F 'package:'
PKG=$(docker exec "$C" dumpsys package com.YoStarEN.AzurLane | grep -m2 -E 'versionName=|versionCode=' || true)
echo "$PKG"
GAME_KIB=$(docker exec "$C" du -sk /data/media/0/Android/data/com.YoStarEN.AzurLane 2>/dev/null | awk '{print $1}' || true)
echo "game_data_kib=$GAME_KIB"
[ -n "$GAME_KIB" ] && [ "$GAME_KIB" -gt 25000000 ] || { echo 'ERROR: game data below expected floor'; false; }

DISPLAY=$(docker exec "$C" dumpsys display 2>/dev/null | grep -m3 -E 'renderFrameRate|fps|1280 x 720|1280x720' || true)
printf 'display_probe:\n%s\n' "$DISPLAY"
SF=$(docker exec "$C" dumpsys SurfaceFlinger 2>/dev/null | grep -m2 -E 'refresh-rate|refreshRate|fps' || true)
printf 'surfaceflinger_probe:\n%s\n' "$SF"

cp -a "$LAUNCHER" "${LAUNCHER}.prefps${CURRENT_FPS}-${STAMP}"
sed -i -E "s/androidboot\.redroid_fps=[0-9]+/androidboot.redroid_fps=${TARGET_FPS}/" "$LAUNCHER"
grep -q "androidboot.redroid_fps=${TARGET_FPS}" "$LAUNCHER"
chown ubuntu:ubuntu "$LAUNCHER" "${LAUNCHER}.prefps${CURRENT_FPS}-${STAMP}" "$LOG"
chmod 0755 "$LAUNCHER"
printf '%s\n' "$OLD" > /home/ubuntu/alcloud-redroid-fps-rollback-container.txt
chown ubuntu:ubuntu /home/ubuntu/alcloud-redroid-fps-rollback-container.txt
sync

echo "[$(date -u +%FT%TZ)] FPS_SWITCH_PASS current=$TARGET_FPS rollback=$OLD"
trap - ERR
