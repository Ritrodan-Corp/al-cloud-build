#!/bin/bash
set -Eeuo pipefail

C=alcloud-redroid-smoke
REF=/home/ubuntu/alcloud-redroid-60hz-rollback-container.txt
DATA=/var/lib/alcloud-redroid/data
LOG=/home/ubuntu/alcloud-redroid-30hz-restore.log
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
SIXTY="${C}-60hz-${STAMP}"
OLD=
RENAMED60=0
RENAMED30=0
STARTED30=0

exec > >(tee -a "$LOG") 2>&1
printf '\n[%s] restore 30Hz start\n' "$(date -u +%FT%TZ)"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: root privileges required"
  exit 2
fi

rollback() {
  rc=$?
  [ "$rc" -eq 0 ] && return
  trap - ERR
  echo "[$(date -u +%FT%TZ)] ERROR rc=$rc; rollback beginning"
  if [ "$STARTED30" -eq 1 ]; then
    docker stop -t 10 "$C" >/dev/null 2>&1 || true
  fi
  if [ "$RENAMED30" -eq 1 ]; then
    docker rename "$C" "$OLD" >/dev/null 2>&1 || true
  fi
  if [ "$RENAMED60" -eq 1 ]; then
    docker rename "$SIXTY" "$C" >/dev/null 2>&1 || true
    docker start "$C" >/dev/null 2>&1 || true
  fi
  echo "[$(date -u +%FT%TZ)] rollback attempted"
  exit "$rc"
}
trap rollback ERR

[ -s "$REF" ] || { echo "ERROR: rollback reference missing: $REF"; exit 3; }
OLD=$(cat "$REF")
echo "rollback_container=$OLD"
docker inspect "$C" >/dev/null
docker inspect "$OLD" >/dev/null

CURCMD=$(docker inspect -f '{{json .Config.Cmd}}' "$C")
OLDCMD=$(docker inspect -f '{{json .Config.Cmd}}' "$OLD")
printf '%s' "$CURCMD" | grep -F 'androidboot.redroid_fps=60' >/dev/null
printf '%s' "$OLDCMD" | grep -F 'androidboot.redroid_fps=30' >/dev/null

CURMOUNT=$(docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}')
OLDMOUNT=$(docker inspect "$OLD" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}')
[ "$CURMOUNT" = "bind $DATA -> /data" ]
[ "$OLDMOUNT" = "bind $DATA -> /data" ]
[ "$(docker exec "$C" getprop sys.boot_completed)" = 1 ]

echo "[$(date -u +%FT%TZ)] quiescing 60Hz runtime"
docker exec "$C" sh -c 'am force-stop com.YoStarEN.AzurLane >/dev/null 2>&1 || true; sync'
docker stop -t 30 "$C" >/dev/null
docker rename "$C" "$SIXTY"
RENAMED60=1

docker rename "$OLD" "$C"
RENAMED30=1
docker start "$C" >/dev/null
STARTED30=1

BOOT=0
for _ in $(seq 1 120); do
  if [ "$(docker exec "$C" getprop sys.boot_completed 2>/dev/null || true)" = 1 ]; then
    BOOT=1
    break
  fi
  sleep 1
done
[ "$BOOT" -eq 1 ] || { echo "ERROR: restored 30Hz Android did not complete boot"; false; }

docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}' | grep -F "bind $DATA -> /data"
docker exec "$C" pm path com.YoStarEN.AzurLane | grep -F 'package:'
DISPLAY=$(docker exec "$C" dumpsys display)
printf '%s\n' "$DISPLAY" | grep -m1 'DisplayDeviceInfo' | tee /home/ubuntu/alcloud-redroid-30hz-display.txt
printf '%s' "$DISPLAY" | grep -E '1280 x 720.*(fps|renderFrameRate) 30(\.0+)?' >/dev/null || {
  echo "ERROR: physical 1280x720 30Hz mode not confirmed"
  false
}

# Restored runtime validated. The 60Hz container has no unique data because /data is external.
docker rm "$SIXTY" >/dev/null
RENAMED60=0
printf '%s\n' "$C" > /home/ubuntu/alcloud-redroid-active-container.txt
chown ubuntu:ubuntu "$LOG" /home/ubuntu/alcloud-redroid-30hz-display.txt /home/ubuntu/alcloud-redroid-active-container.txt
sync
echo "[$(date -u +%FT%TZ)] RESTORE_PASS"
echo "active_runtime=$C 1280x720@30Hz"
echo "persistent_data=$DATA"
trap - ERR
