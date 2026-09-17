#!/bin/bash
set -Eeuo pipefail

C=alcloud-redroid-smoke
DATA=/var/lib/alcloud-redroid/data
LOG=/home/ubuntu/alcloud-redroid-60hz-experiment.log
REF=/home/ubuntu/alcloud-redroid-60hz-rollback-container.txt
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OLD="${C}-30hz-${STAMP}"
RENAMED=0
NEW_STARTED=0

exec > >(tee -a "$LOG") 2>&1
printf '\n[%s] 60Hz experiment start\n' "$(date -u +%FT%TZ)"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: root privileges required"
  exit 2
fi

rollback() {
  rc=$?
  [ "$rc" -eq 0 ] && return
  trap - ERR
  echo "[$(date -u +%FT%TZ)] ERROR rc=$rc; restoring 30Hz runtime"
  if [ "$NEW_STARTED" -eq 1 ]; then
    docker rm -f "$C" >/dev/null 2>&1 || true
  fi
  if [ "$RENAMED" -eq 1 ]; then
    docker rename "$OLD" "$C" >/dev/null 2>&1 || true
    docker start "$C" >/dev/null 2>&1 || true
  fi
  echo "[$(date -u +%FT%TZ)] rollback attempted"
  exit "$rc"
}
trap rollback ERR

docker inspect "$C" >/dev/null
[ "$(docker inspect -f '{{.State.Running}}' "$C")" = true ]
CMD=$(docker inspect -f '{{json .Config.Cmd}}' "$C")
echo "current_cmd=$CMD"
printf '%s' "$CMD" | grep -F 'androidboot.redroid_width=1280' >/dev/null
printf '%s' "$CMD" | grep -F 'androidboot.redroid_height=720' >/dev/null
printf '%s' "$CMD" | grep -F 'androidboot.redroid_fps=30' >/dev/null
MOUNT=$(docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}')
echo "current_data_mount=$MOUNT"
[ "$MOUNT" = "bind $DATA -> /data" ]
[ "$(docker exec "$C" getprop sys.boot_completed)" = 1 ]
docker exec "$C" pm path com.YoStarEN.AzurLane | grep -F 'package:'
GAME_KIB=$(docker exec "$C" du -sk /data/media/0/Android/data/com.YoStarEN.AzurLane 2>/dev/null | awk '{print $1}')
echo "game_data_kib=$GAME_KIB"
[ "$GAME_KIB" -gt 25000000 ]

echo "[$(date -u +%FT%TZ)] quiescing 30Hz runtime"
docker exec "$C" sh -c 'am force-stop com.YoStarEN.AzurLane >/dev/null 2>&1 || true; sync'
docker stop -t 30 "$C" >/dev/null
docker rename "$C" "$OLD"
RENAMED=1
printf '%s\n' "$OLD" > "$REF"
chown ubuntu:ubuntu "$REF"

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
  androidboot.redroid_fps=60)
NEW_STARTED=1
echo "new_container_id=$NEW_ID"

BOOT=0
for _ in $(seq 1 120); do
  if [ "$(docker exec "$C" getprop sys.boot_completed 2>/dev/null || true)" = 1 ]; then
    BOOT=1
    break
  fi
  sleep 1
done
[ "$BOOT" -eq 1 ] || { echo "ERROR: 60Hz Android did not complete boot"; false; }

docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}' | grep -F "bind $DATA -> /data"
docker exec "$C" pm path com.YoStarEN.AzurLane | grep -F 'package:'
DISPLAY=$(docker exec "$C" dumpsys display)
printf '%s\n' "$DISPLAY" | grep -m1 'DisplayDeviceInfo' | tee /home/ubuntu/alcloud-redroid-60hz-display.txt
printf '%s' "$DISPLAY" | grep -E '1280 x 720.*(fps|renderFrameRate) 60(\.0+)?' >/dev/null || {
  echo "ERROR: physical 1280x720 60Hz mode not confirmed"
  false
}

chown ubuntu:ubuntu "$LOG" /home/ubuntu/alcloud-redroid-60hz-display.txt
sync
echo "[$(date -u +%FT%TZ)] EXPERIMENT_READY"
echo "active_runtime=$C 1280x720@60Hz"
echo "rollback_container=$OLD"
echo "persistent_data=$DATA"
echo "permanent_launcher_unchanged=30Hz"
trap - ERR
