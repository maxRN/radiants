#!/bin/sh
set -eu

mkdir -p /root/.ssh /mnt/ssh /data/rclone-cache
chmod 700 /root/.ssh

if [ -z "${STORAGEBOX_SSH_KEY:-}" ]; then
  echo "error: STORAGEBOX_SSH_KEY secret is not set" >&2
  exit 1
fi

printf '%s\n' "$STORAGEBOX_SSH_KEY" > /root/.ssh/id_ed25519
chmod 600 /root/.ssh/id_ed25519

ssh-keyscan -p "${RCLONE_CONFIG_BOX_PORT:-23}" "${RCLONE_CONFIG_BOX_HOST:-u462951.your-storagebox.de}" >> /root/.ssh/known_hosts 2>/dev/null || true
chmod 644 /root/.ssh/known_hosts

export RCLONE_CONFIG_BOX_TYPE="${RCLONE_CONFIG_BOX_TYPE:-sftp}"
export RCLONE_CONFIG_BOX_HOST="${RCLONE_CONFIG_BOX_HOST:-u462951.your-storagebox.de}"
export RCLONE_CONFIG_BOX_USER="${RCLONE_CONFIG_BOX_USER:-u462951}"
export RCLONE_CONFIG_BOX_PORT="${RCLONE_CONFIG_BOX_PORT:-23}"
export RCLONE_CONFIG_BOX_KEY_FILE="${RCLONE_CONFIG_BOX_KEY_FILE:-/root/.ssh/id_ed25519}"

echo "mounting storage box at /mnt/ssh..."
rclone mount "box:" /mnt/ssh \
  --allow-other \
  --uid 0 \
  --gid 0 \
  --umask 000 \
  --dir-perms 0777 \
  --file-perms 0666 \
  --vfs-cache-mode full \
  --vfs-cache-max-size 2G \
  --vfs-read-ahead 128M \
  --cache-dir /data/rclone-cache \
  --dir-cache-time 72h \
  --log-level INFO \
  --log-file /data/rclone-cache/rclone.log &

mount_pid=$!
attempt=0
while [ "$attempt" -lt 90 ]; do
  if mountpoint -q /mnt/ssh 2>/dev/null && ls /mnt/ssh/audiobooks >/dev/null 2>&1; then
    echo "storage box mounted at /mnt/ssh"
    break
  fi

  if ! kill -0 "$mount_pid" 2>/dev/null; then
    echo "error: rclone mount exited before /mnt/ssh became available" >&2
    tail -20 /data/rclone-cache/rclone.log 2>/dev/null || true
    wait "$mount_pid" || true
    exit 1
  fi

  attempt=$((attempt + 1))
  sleep 1
done

if ! ls /mnt/ssh/audiobooks >/dev/null 2>&1; then
  echo "error: storage box mount is not readable at /mnt/ssh/audiobooks" >&2
  ls -la /mnt/ssh 2>&1 || true
  rclone lsf "box:audiobooks" 2>&1 | head -5 || true
  tail -20 /data/rclone-cache/rclone.log 2>/dev/null || true
  kill "$mount_pid" 2>/dev/null || true
  exit 1
fi

cleanup() {
  if kill -0 "$mount_pid" 2>/dev/null; then
    kill "$mount_pid" 2>/dev/null || true
    wait "$mount_pid" 2>/dev/null || true
  fi

  if mountpoint -q /mnt/ssh 2>/dev/null; then
    fusermount3 -u /mnt/ssh 2>/dev/null || fusermount -u /mnt/ssh 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

crond -b -l 8

exec tini -s -- "$@"
