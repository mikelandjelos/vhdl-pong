#!/bin/bash

# Clean previous build
rm -rf work-obj 2>/dev/null || true
mkdir -p work-obj
mkdir -p frames
rm -f frames/frame_*.ppm frames/out.gif 2>/dev/null || true

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
ghdl -a --workdir=work-obj --work=lib vga_controller.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib vga_tb.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib top_vga.vhd || exit 1
ghdl -a --workdir=work-obj --work=lib vga_video_tb.vhd || exit 1
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
echo "Running vga_tb (writes frame.ppm)..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib vga_tb || exit 1
ghdl -r --workdir=work-obj --work=lib vga_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Running vga_video_tb (writes frames/*.ppm)..."
echo "========================================="
ghdl -e --workdir=work-obj --work=lib vga_video_tb || exit 1
ghdl -r --workdir=work-obj --work=lib vga_video_tb --assert-level=error || exit 1

echo ""
echo "========================================="
echo "Converting frames to GIF (frames/out.gif)..."
echo "========================================="
if command -v convert >/dev/null 2>&1; then
  convert -delay 4 -loop 0 frames/frame_*.ppm frames/out.gif || {
    echo "ImageMagick convert failed."; exit 1; }
  echo "GIF created: frames/out.gif"
elif command -v ffmpeg >/dev/null 2>&1; then
  ffmpeg -y -framerate 30 -i frames/frame_%04d.ppm frames/out.gif || {
    echo "ffmpeg conversion failed."; exit 1; }
  echo "GIF created: frames/out.gif"
else
  echo "No converter found (need ImageMagick 'convert' or 'ffmpeg')."
fi

echo ""
echo "========================================="
echo "All tests completed!"
echo "========================================="
