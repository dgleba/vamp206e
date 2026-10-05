#!/usr/bin/env bash
set -euo pipefail
set -vx 

# ---- CONFIGURE YOUR WINDOW HERE ---- 15 minutes before crash or event.
START="2026-06-11 16:15:00"
END="2026-06-12 07:58:22"
# ------------------------------------

TS="$(date +%Y%m%d_%H%M%S)"
OUT="logs_window_$TS"
mkdir -p "$OUT"

echo "Collecting logs from:"
echo "  START = $START"
echo "  END   = $END"
echo "  OUT   = $OUT"
echo

# --- SYSTEMD JOURNAL (PRIMARY SOURCE) ---
journalctl --since "$START" --until "$END" \
  > "$OUT/journal_full.log.txt"

journalctl -k --since "$START" --until "$END" \
  > "$OUT/journal_kernel.log.txt"

journalctl -u docker --since "$START" --until "$END" \
  > "$OUT/journal_docker.log.txt" 2>/dev/null || true

journalctl -u NetworkManager --since "$START" --until "$END" \
  > "$OUT/journal_network.log.txt" 2>/dev/null || true

journalctl -u systemd-logind --since "$START" --until "$END" \
  > "$OUT/journal_logind.log.txt" 2>/dev/null || true

# --- OPTIONAL: SYSLOG MIRROR (FAST, NO DATE PARSING) ---
if [ -f /var/log/syslog ]; then
  grep -E "^(Jun|Jul|Aug|Sep|Oct|Nov|Dec|Jan|Feb|Mar|Apr|May)" /var/log/syslog \
    | sed -n "/$(date -d "$START" '+%b %_d %H:%M')/,\ 
              /$(date -d "$END"   '+%b %_d %H:%M')/p" \
    > "$OUT/syslog_window.log.txt" || true
fi

# --- XORG / WAYLAND LOGS ---
cp ~/.local/share/xorg/Xorg.0.log "$OUT/Xorg.0.log.txt" 2>/dev/null || true
cp ~/.local/share/xorg/Xorg.1.log "$OUT/Xorg.1.log.txt" 2>/dev/null || true
cp ~/.xsession-errors "$OUT/xsession-errors.log.txt" 2>/dev/null || true

# --- CRASH DUMPS ---
ls -lh /var/crash/ > "$OUT/var_crash_listing.txt" 2>/dev/null || true
cp /var/crash/* "$OUT/" 2>/dev/null || true

# --- HARDWARE SNAPSHOT ---
lspci -nnvv > "$OUT/lspci.log.txt"
lsusb -vvv > "$OUT/lsusb.log.txt" 2>/dev/null || true
lsblk -o NAME,SIZE,MODEL,SERIAL > "$OUT/lsblk.log.txt"

echo "Done."
echo "Logs saved to: $OUT/"

