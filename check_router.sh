#!/usr/bin/env bash
set -u

# check_router.sh
# Generic script to verify connectivity to a local router and attempt a Wi‑Fi
# reconnect using NetworkManager (nmcli) when the ping fails.
# Configure via environment variables; see README.md for details.

ROUTER="${ROUTER:-192.168.0.1}"
PING_COUNT="${PING_COUNT:-2}"
PING_TIMEOUT="${PING_TIMEOUT:-2}"
LOG_TAG="${LOG_TAG:-check-router}"
TARGET="${TARGET:-}"
RECONNECT_METHOD="${RECONNECT_METHOD:-device}" # device|radio

log() { logger -t "$LOG_TAG" "$*"; }

command -v nmcli >/dev/null 2>&1 || { log "nmcli not found"; exit 10; }

# quick ping test
if ping -c "$PING_COUNT" -W "$PING_TIMEOUT" -q "$ROUTER" >/dev/null 2>&1; then
  exit 0
fi

log "Ping to $ROUTER failed; attempting Wi‑Fi reconnect"

# find first wifi device
wifi_line=$(nmcli -t -f DEVICE,TYPE,STATE device | awk -F: '$2=="wifi"{print $1":"$3; exit}')
if [ -z "${wifi_line:-}" ]; then
  log "No Wi‑Fi device found"
  exit 2
fi

IFS=":" read -r IFACE STATE <<< "$wifi_line"

if [ -z "${IFACE:-}" ]; then
  log "Unable to determine Wi‑Fi interface"
  exit 3
fi

if [ "$STATE" != "disconnected" ]; then
  if [ "$RECONNECT_METHOD" = "radio" ]; then
    log "Toggling Wi‑Fi radio off/on for $IFACE (state=$STATE)"
    nmcli radio wifi off >/dev/null 2>&1 || log "nmcli radio off failed"
    sleep 2
    nmcli radio wifi on >/dev/null 2>&1 || log "nmcli radio on failed"
    sleep 2
  else
    log "Disconnecting Wi‑Fi device $IFACE (state=$STATE)"
    nmcli device disconnect "$IFACE" >/dev/null 2>&1 || log "nmcli disconnect returned nonzero for $IFACE"
    sleep 2
  fi
else
  log "Wi‑Fi device $IFACE already disconnected"
fi

if [ -n "${TARGET}" ]; then
  log "Bringing up target connection '$TARGET'"
  nmcli connection down "$TARGET" >/dev/null 2>&1 || true
  nmcli connection up "$TARGET" >/dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    log "connection up by name failed for '$TARGET' (exit $rc), falling back to device connect"
    nmcli device connect "$IFACE" >/dev/null 2>&1 || log "device connect also failed"
    rc=$?
    if [ $rc -ne 0 ]; then
      log "nmcli connect failed for $IFACE (exit $rc)"
      exit 4
    fi
  fi
else
  log "Connecting Wi‑Fi device $IFACE"
  nmcli device connect "$IFACE" >/dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    log "nmcli connect failed for $IFACE (exit $rc)"
    exit 4
  fi
fi

sleep 5
# verify connectivity after reconnect
if ping -c 1 -W 2 -q "$ROUTER" >/dev/null 2>&1; then
  log "Ping to $ROUTER succeeded after reconnect"
  exit 0
else
  log "Ping still failing after reconnect"
  exit 5
fi
