#!/bin/bash

# Clean previous build
rm -rf work-obj 2>/dev/null || true
mkdir -p work-obj
mkdir -p frames
rm -f frames/frame_*.ppm frames/out.gif frames/stream.rgb frames/live.mp4 2>/dev/null || true

echo "========================================="
echo "Preparing environment..."
echo "========================================="

# Minimal playable mode (ffplay streaming) when PLAY=1
if [ "${PLAY:-0}" = "1" ]; then
  echo "PLAY=1 → minimal playable build"
  ghdl -a --workdir=work-obj --work=lib vga_play_tb.vhd || exit 1
  ghdl -e --workdir=work-obj --work=lib vga_play_tb || exit 1

  PLAY_WIDTH=${PLAY_WIDTH:-640}
  PLAY_HEIGHT=${PLAY_HEIGHT:-480}
  PLAY_FPS=${PLAY_FPS:-90}
  TOTAL_PLAY_FRAMES=${TOTAL_PLAY_FRAMES:-0}
  STREAM_PATH=frames/stream.rgb
  CTRL_PATH=frames/controls.txt

  rm -f "$STREAM_PATH" "$CTRL_PATH" 2>/dev/null || true
  mkfifo "$STREAM_PATH" || { echo "mkfifo failed"; exit 1; }
  echo 0 > "$CTRL_PATH"

  if command -v ffplay >/dev/null 2>&1; then
    # Stream FIFO via cat → ffplay for minimal latency
    cat "$STREAM_PATH" | \
      ffplay -autoexit -hide_banner -loglevel warning \
             -f rawvideo -pixel_format rgb24 \
             -video_size ${PLAY_WIDTH}x${PLAY_HEIGHT} -framerate ${PLAY_FPS} \
             -i pipe:0 &
    PLAYER_PID=$!
  elif command -v ffmpeg >/dev/null 2>&1; then
    echo "ffplay not found; recording to frames/live.mp4"
    cat "$STREAM_PATH" | \
      ffmpeg -y -hide_banner -loglevel error \
             -f rawvideo -pixel_format rgb24 \
             -video_size ${PLAY_WIDTH}x${PLAY_HEIGHT} -framerate ${PLAY_FPS} \
             -i pipe:0 -pix_fmt yuv420p frames/live.mp4 &
    PLAYER_PID=$!
  else
    echo "Neither ffplay nor ffmpeg found; cannot display/record."; exit 1
  fi

  echo "Controls: run ./play_controls.sh in another terminal (W/S for P1, I/K for P2, Q to quit)."

  echo "Starting vga_play_tb ..."
  ghdl -r --workdir=work-obj --work=lib vga_play_tb \
       -gWIDTH=$PLAY_WIDTH -gHEIGHT=$PLAY_HEIGHT \
       -gN_FRAMES=$TOTAL_PLAY_FRAMES -gFRAMERATE=$PLAY_FPS \
       -gOUT_PATH="$STREAM_PATH" -gCTRL_PATH="$CTRL_PATH" || true

  if [ -n "$PLAYER_PID" ]; then kill $PLAYER_PID 2>/dev/null || true; fi
  rm -f "$STREAM_PATH" "$CTRL_PATH" 2>/dev/null || true
  echo "========================================="
  echo "Playable session ended."
  echo "========================================="
  exit 0
fi

echo "========================================="
echo "Compiling design files..."
echo "========================================="

# Compile in order (dependencies first)
ghdl -a --workdir=work-obj --work=lib test_helpers.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib 7seg.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib clk_div.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_7seg.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib score_7seg.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_score7seg.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib score_7seg_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_score7seg_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib input_controller.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib input_controller_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib vga_controller.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib vga_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_vga.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib vga_fast_stream_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib 7seg_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_7seg_tb.vhd || exit 1

echo ""
echo "========================================="
echo "Running tb_7seg..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib tb_7seg || exit 1
ghdl -r --workdir=work-obj --work=lib tb_7seg --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running top_7seg_tb..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib top_7seg_tb || exit 1
ghdl -r --workdir=work-obj --work=lib top_7seg_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running score_7seg_tb..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib score_7seg_tb || exit 1
ghdl -r --workdir=work-obj --work=lib score_7seg_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running top_score7seg_tb..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib top_score7seg_tb || exit 1
ghdl -r --workdir=work-obj --work=lib top_score7seg_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running input_controller_tb..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib input_controller_tb || exit 1
ghdl -r --workdir=work-obj --work=lib input_controller_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running vga_tb (writes frame.ppm)..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib vga_tb || exit 1
ghdl -r --workdir=work-obj --work=lib vga_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Generating GIF with vga_fast_stream_tb (raw RGB -> ffmpeg)"
echo "========================================="

TOTAL_STREAM_FRAMES=${TOTAL_STREAM_FRAMES:-120}
STREAM_WIDTH=${STREAM_WIDTH:-640}
STREAM_HEIGHT=${STREAM_HEIGHT:-480}
STREAM_FRAMERATE=${STREAM_FRAMERATE:-30}
GIF_WIDTH=${GIF_WIDTH:-320}
GIF_HEIGHT=${GIF_HEIGHT:-240}
GIF_PATH=${GIF_PATH:-frames/out.gif}
STREAM_PATH=frames/stream.rgb

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ffmpeg not found. Install ffmpeg to generate GIF quickly."; exit 1
fi

# Prepare FIFO for streaming
rm -f "$STREAM_PATH" 2>/dev/null || true
mkfifo "$STREAM_PATH" || { echo "mkfifo failed"; exit 1; }

# Start ffmpeg to read raw RGB and write optimized GIF with palette in one pass
echo "Launching ffmpeg to write $GIF_PATH ..."
ffmpeg -y -hide_banner -loglevel error \
       -f rawvideo -pixel_format rgb24 \
       -video_size ${STREAM_WIDTH}x${STREAM_HEIGHT} -framerate ${STREAM_FRAMERATE} \
       -i "$STREAM_PATH" \
       -filter_complex "scale=${GIF_WIDTH}:${GIF_HEIGHT}:flags=area,split[s0][s1];[s0]palettegen=stats_mode=single[p];[s1][p]paletteuse=new=1" \
       "$GIF_PATH" &
FFMPEG_PID=$!

echo "Streaming ${TOTAL_STREAM_FRAMES} frames to ffmpeg..."
ghdl -e --workdir=work-obj --work=lib vga_fast_stream_tb || exit 1
ghdl -r --workdir=work-obj --work=lib vga_fast_stream_tb \
     -gWIDTH=$STREAM_WIDTH -gHEIGHT=$STREAM_HEIGHT \
     -gN_FRAMES=$TOTAL_STREAM_FRAMES -gFRAMERATE=$STREAM_FRAMERATE \
     -gOUT_PATH="$STREAM_PATH" || exit 1

# Wait for ffmpeg to finish consuming the stream
wait $FFMPEG_PID || true
rm -f "$STREAM_PATH" 2>/dev/null || true

echo "GIF created: $GIF_PATH"
