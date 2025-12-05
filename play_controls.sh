#!/usr/bin/env bash
# Simple keyboard→controls.txt bridge for vga_play_tb (low-latency).
# Usage: ./play_controls.sh [frames/controls.txt]

CTRL_PATH=${1:-frames/controls.txt}
mkdir -p "$(dirname "$CTRL_PATH")"
echo 0 > "$CTRL_PATH"

tick_ms=${TICK_MS:-5}    # update period (ms)
ttl_ms=${TTL_MS:-5}    # how long a key stays active without repeats (ms)

ttl_ticks=$(( ttl_ms / tick_ms ))
(( ttl_ticks < 1 )) && ttl_ticks=1

w=0; s=0; i=0; k=0

if [ ! -t 0 ]; then
  echo "play_controls.sh: stdin not a TTY. Run this script in a terminal window." >&2
  exit 1
fi

stty -echo -icanon time 0 min 0
trap 'stty sane; exit' INT TERM EXIT

echo "Controls: w/s for P1, i/k for P2, q to quit"
echo "Tip: hold keys; release stops after ~${TTL_MS}ms."
printf "\n"
print_status() {
  local s_up=$([ $w -gt 0 ] && echo ON || echo off)
  local s_dn=$([ $s -gt 0 ] && echo ON || echo off)
  local r_up=$([ $i -gt 0 ] && echo ON || echo off)
  local r_dn=$([ $k -gt 0 ] && echo ON || echo off)
  printf "\rP1[W:%-3s S:%-3s]  P2[Up:%-3s Down:%-3s]  mask=%d   " "$s_up" "$s_dn" "$r_up" "$r_dn" "$mask"
}
while true; do
  # non-blocking 10ms read
  if read -rsn1 -t 0.01 ch; then
    case "$ch" in
      q|Q) echo -1 > "$CTRL_PATH"; break ;;
      w|W) w=$ttl_ticks ;;
      s|S) s=$ttl_ticks ;;
      i|I) i=$ttl_ticks ;;
      k|K) k=$ttl_ticks ;;
    esac
  fi

  # compute mask with current TTLs
  mask=0
  (( w > 0 )) && mask=$((mask|1))
  (( s > 0 )) && mask=$((mask|2))
  (( i > 0 )) && mask=$((mask|4))
  (( k > 0 )) && mask=$((mask|8))
  echo $mask > "$CTRL_PATH"
  print_status

  # decay
  (( w>0 )) && w=$((w-1))
  (( s>0 )) && s=$((s-1))
  (( i>0 )) && i=$((i-1))
  (( k>0 )) && k=$((k-1))

  sleep 0.03
done
printf "\n"
