#!/bin/bash
set -Eeuo pipefail

C=alcloud-redroid-smoke
TARGET=/var/lib/alcloud-redroid/data
PARENT=/var/lib/alcloud-redroid
LAUNCHER=/home/ubuntu/alcloud-start-redroid-smoke.sh
LOG=/home/ubuntu/alcloud-migrate-redroid-data.log
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OLD="${C}-prepersist-${STAMP}"
BACKUP="${LAUNCHER}.prepersist-${STAMP}"
APPLY=0
[ "${1:-}" = "--apply" ] && APPLY=1

MOVED=0
RENAMED=0
NEW_STARTED=0
UPPER=

exec > >(tee -a "$LOG") 2>&1
printf '\n[%s] migration invocation apply=%s\n' "$(date -u +%FT%TZ)" "$APPLY"

if [ "$(id -u)" -ne 0 ]; then
  echo "ERROR: root privileges are required"
  exit 2
fi

rollback() {
  rc=$?
  [ "$rc" -eq 0 ] && return
  trap - ERR
  echo "[$(date -u +%FT%TZ)] ERROR rc=$rc; rollback beginning"
  if [ "$NEW_STARTED" -eq 1 ]; then
    docker rm -f "$C" >/dev/null 2>&1 || true
  fi
  if [ "$RENAMED" -eq 1 ]; then
    docker rename "$OLD" "$C" >/dev/null 2>&1 || true
  fi
  if [ "$MOVED" -eq 1 ] && [ -n "$UPPER" ] && [ -d "$TARGET" ]; then
    if [ ! -e "$UPPER/data" ]; then
      mv "$TARGET" "$UPPER/data" || true
    fi
  fi
  if docker inspect "$C" >/dev/null 2>&1; then
    docker start "$C" >/dev/null 2>&1 || true
  fi
  echo "[$(date -u +%FT%TZ)] rollback attempted; inspect runtime before retry"
  exit "$rc"
}
trap rollback ERR

if ! docker inspect "$C" >/dev/null 2>&1; then
  echo "ERROR: container $C not found"
  exit 3
fi
if [ "$(docker inspect -f '{{.State.Running}}' "$C")" != true ]; then
  echo "ERROR: $C is not running"
  exit 4
fi

MERGED=$(docker inspect -f '{{index .GraphDriver.Data "MergedDir"}}' "$C" 2>/dev/null || true)
if [ -z "$MERGED" ] || [ ! -d "$MERGED" ]; then
  MERGED=$(findmnt -t overlay -n -o TARGET | grep '^/var/lib/docker/rootfs/overlayfs/' | head -1 || true)
fi
[ -n "$MERGED" ] && [ -d "$MERGED" ] || { echo "ERROR: cannot resolve merged root"; exit 5; }

OPTS=$(findmnt -T "$MERGED" -n -o OPTIONS)
UPPER=$(printf '%s' "$OPTS" | tr ',' '\n' | sed -n 's/^upperdir=//p')
LOWERS=$(printf '%s' "$OPTS" | tr ',' '\n' | sed -n 's/^lowerdir=//p')
[ -n "$UPPER" ] && [ -d "$UPPER/data" ] || { echo "ERROR: writable-layer /data not found"; exit 6; }

printf 'container=%s\nmerged=%s\nupper=%s\nlower=%s\n' "$C" "$MERGED" "$UPPER" "$LOWERS"
echo "upper_data_size=$(du -sb "$UPPER/data" | awk '{print $1}')"
echo "upper_data_blocks=$(du -sk "$UPPER/data" | awk '{print $1}')KiB"
echo "free_before=$(df -B1 / | awk 'NR==2{print $4}')"

OPAQUE=$(getfattr --only-values -n trusted.overlay.opaque "$UPPER/data" 2>/dev/null || true)
printf 'upper_data_opaque=%q\n' "$OPAQUE"
LOWER_NONEMPTY=0
IFS=: read -r -a LOWER_ARRAY <<< "$LOWERS"
for l in "${LOWER_ARRAY[@]}"; do
  if [ -d "$l/data" ]; then
    sample=$(find "$l/data" -mindepth 1 -maxdepth 2 -print -quit 2>/dev/null || true)
    if [ -n "$sample" ]; then
      echo "lower_data_nonempty=$l/data sample=$sample"
      LOWER_NONEMPTY=1
    else
      echo "lower_data_empty=$l/data"
    fi
  else
    echo "lower_data_absent=$l/data"
  fi
done

WHITEOUT=$(find "$UPPER/data" -xdev -type c -print -quit 2>/dev/null || true)
if [ -n "$WHITEOUT" ]; then
  echo "ERROR: character-device/whiteout found under upper /data: $WHITEOUT"
  exit 7
fi
if [ "$LOWER_NONEMPTY" -eq 1 ] && [ "$OPAQUE" != y ]; then
  echo "ERROR: lower-layer /data contributes content and upper /data is not opaque; direct move is unsafe"
  exit 8
fi
if [ -e "$TARGET" ]; then
  echo "ERROR: target already exists: $TARGET"
  exit 9
fi

UPPER_DEV=$(stat -c %d "$UPPER/data")
VARLIB_DEV=$(stat -c %d /var/lib)
[ "$UPPER_DEV" = "$VARLIB_DEV" ] || { echo "ERROR: source and target parent are not on same filesystem"; exit 10; }

echo "same_filesystem=yes device=$UPPER_DEV"
echo "top_level_before:"
find "$UPPER/data" -mindepth 1 -maxdepth 1 -printf '%f\t%i\t%u:%g\t%m\n' | sort

if [ "$APPLY" -ne 1 ]; then
  echo "PREFLIGHT_PASS: no mutation performed. Re-run with --apply to migrate."
  trap - ERR
  exit 0
fi

echo "[$(date -u +%FT%TZ)] quiescing Android"
docker exec "$C" sh -c 'am force-stop com.YoStarEN.AzurLane >/dev/null 2>&1 || true; sync'
docker stop -t 30 "$C" >/dev/null

INSPECT_BACKUP="/home/ubuntu/alcloud-redroid-prepersist-inspect-${STAMP}.json"
docker inspect "$C" > "$INSPECT_BACKUP"
chown ubuntu:ubuntu "$INSPECT_BACKUP"
DATA_INODE_BEFORE=$(stat -c %i "$UPPER/data")
DATA_BYTES_BEFORE=$(du -sb "$UPPER/data" | awk '{print $1}')

mkdir -p "$PARENT"
chmod 0755 "$PARENT"
[ ! -e "$TARGET" ]
mv "$UPPER/data" "$TARGET"
MOVED=1
sync
[ -d "$TARGET" ] && [ ! -e "$UPPER/data" ]
DATA_INODE_AFTER=$(stat -c %i "$TARGET")
DATA_BYTES_AFTER=$(du -sb "$TARGET" | awk '{print $1}')
[ "$DATA_INODE_AFTER" = "$DATA_INODE_BEFORE" ] || { echo "ERROR: data inode changed across same-filesystem move"; false; }
[ "$DATA_BYTES_AFTER" = "$DATA_BYTES_BEFORE" ] || { echo "ERROR: data byte count changed across quiesced move"; false; }
echo "move_identity_ok inode=$DATA_INODE_AFTER bytes=$DATA_BYTES_AFTER"

echo "[$(date -u +%FT%TZ)] data moved in-place to $TARGET"
echo "target_size=$(du -sb "$TARGET" | awk '{print $1}')"
echo "free_after_move=$(df -B1 / | awk 'NR==2{print $4}')"

docker rename "$C" "$OLD"
RENAMED=1
printf '%s\n' "$OLD" > /home/ubuntu/alcloud-redroid-prepersist-container.txt
chown ubuntu:ubuntu /home/ubuntu/alcloud-redroid-prepersist-container.txt

NEW_ID=$(docker run -d --name "$C" --privileged \
  --mount type=bind,src="$TARGET",dst=/data \
  -v /dev/binderfs/binder:/dev/binder \
  -v /dev/binderfs/hwbinder:/dev/hwbinder \
  -v /dev/binderfs/vndbinder:/dev/vndbinder \
  -p 127.0.0.1:5555:5555 \
  redroid/redroid:14.0.0_64only-latest \
  androidboot.redroid_gpu_mode=guest \
  androidboot.use_memfd=true \
  androidboot.redroid_width=1280 \
  androidboot.redroid_height=720 \
  androidboot.redroid_fps=30)
NEW_STARTED=1
echo "new_container_id=$NEW_ID"

BOOT=0
for _ in $(seq 1 90); do
  if [ "$(docker exec "$C" getprop sys.boot_completed 2>/dev/null || true)" = 1 ]; then BOOT=1; break; fi
  sleep 1
done
[ "$BOOT" -eq 1 ] || { echo "ERROR: new Android did not complete boot"; false; }

docker inspect "$C" --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}} {{.Source}} -> {{.Destination}}{{end}}{{end}}' | grep -F "bind $TARGET -> /data"
docker exec "$C" pm path com.YoStarEN.AzurLane | grep -F 'package:'
PKG=$(docker exec "$C" dumpsys package com.YoStarEN.AzurLane | grep -m1 -E 'versionName=|versionCode=' || true)
echo "package_check=$PKG"
GAME_KIB=$(docker exec "$C" du -sk /data/media/0/Android/data/com.YoStarEN.AzurLane 2>/dev/null | awk '{print $1}' || true)
echo "game_data_kib=$GAME_KIB"
[ -n "$GAME_KIB" ] && [ "$GAME_KIB" -gt 25000000 ] || { echo "ERROR: Azur Lane game data size below expected floor"; false; }

echo "top_level_after:"
find "$TARGET" -mindepth 1 -maxdepth 1 -printf '%f\t%i\t%u:%g\t%m\n' | sort

cp -a "$LAUNCHER" "$BACKUP"
cat > "$LAUNCHER" <<'LAUNCH'
#!/bin/bash
set -euo pipefail
DATA=/var/lib/alcloud-redroid/data
[ -d "$DATA" ] || { echo "Missing persistent ReDroid data: $DATA" >&2; exit 1; }
[ -d "$DATA/media" ] || { echo "Persistent ReDroid data is incomplete: $DATA/media missing" >&2; exit 1; }
docker rm -f alcloud-redroid-smoke >/dev/null 2>&1 || true
docker run -d --name alcloud-redroid-smoke --privileged \
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
  androidboot.redroid_fps=30
echo "ReDroid persistent container started."
LAUNCH
chmod 0755 "$LAUNCHER"
chown ubuntu:ubuntu "$LAUNCHER" "$BACKUP" "$LOG"

sync
echo "[$(date -u +%FT%TZ)] MIGRATION_PASS"
echo "old_container=$OLD"
echo "persistent_data=$TARGET"
echo "launcher_backup=$BACKUP"
trap - ERR
