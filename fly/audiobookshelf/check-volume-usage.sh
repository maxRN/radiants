#!/bin/sh
set -eu

THRESHOLD="${VOLUME_ALERT_THRESHOLD:-80}"
RESET_BELOW="${VOLUME_ALERT_RESET:-75}"
MOUNT="${VOLUME_ALERT_MOUNT:-/data}"
BRRR_SECRET="${BRRR_USER_SECRET:-}"
STATE_FILE="${MOUNT}/.volume-alert-state"

if [ -z "$BRRR_SECRET" ]; then
  exit 0
fi

USAGE="$(df "$MOUNT" | awk 'NR==2 {print $5}' | tr -d '%')"
USED="$(df -h "$MOUNT" | awk 'NR==2 {print $3}')"
SIZE="$(df -h "$MOUNT" | awk 'NR==2 {print $2}')"
AVAIL="$(df -h "$MOUNT" | awk 'NR==2 {print $4}')"

if [ "$USAGE" -lt "$RESET_BELOW" ]; then
  rm -f "$STATE_FILE"
  exit 0
fi

if [ "$USAGE" -lt "$THRESHOLD" ]; then
  exit 0
fi

if [ -f "$STATE_FILE" ]; then
  LAST="$(cat "$STATE_FILE")"
  NOW="$(date +%s)"
  if [ "$((NOW - LAST))" -lt 86400 ]; then
    exit 0
  fi
fi

MESSAGE="/data is at ${USAGE}% (${USED} used of ${SIZE}, ${AVAIL} free)"
BODY="{\"title\":\"radiants-abs disk\",\"message\":\"${MESSAGE}\",\"thread_id\":\"radiants-abs-disk\"}"

if wget -q -O /dev/null \
  --header="Content-Type: application/json" \
  --header="Authorization: Bearer ${BRRR_SECRET}" \
  --post-data="$BODY" \
  "https://api.brrr.now/v1/send"; then
  date +%s > "$STATE_FILE"
  echo "volume alert sent: ${USAGE}%"
else
  echo "volume alert failed: brrr request error" >&2
  exit 1
fi
