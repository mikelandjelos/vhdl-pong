## VHDL Pong — Play It Live from a Testbench

This repo lets you play a simple Pong game entirely from a VHDL testbench, with live video streamed to `ffplay` or recorded by `ffmpeg`. No FPGA board or vendor suite required.

### Highlights
- VHDL testbenches only — fast functional renderer for gameplay, timing‐accurate VGA for verification
- Live streaming via raw RGB24 → `ffplay` (or MP4 recording via `ffmpeg`)
- Keyboard controls bridged through a tiny shell helper
- Self‑checking unit tests for 7‑segment and input controller

### Requirements
- GHDL (mcode, LLVM or GCC backend)
- `ffplay` (from `ffmpeg`) for live preview, or `ffmpeg` for recording
- Bash (for the helper scripts)

### Quick Start — Play Now
Open two terminals:

1) Video + simulator
```
PLAY=1 bash run_ghdl_tests.sh
```

2) Keyboard controls with on‑screen HUD
```
chmod +x play_controls.sh
./play_controls.sh
```

Controls: `W/S` for Player 1, `I/K` for Player 2, `Q` to quit.

Defaults: 640×480 at 120 FPS for responsive input. You can change size/FPS:
```
PLAY_WIDTH=800 PLAY_HEIGHT=600 PLAY_FPS=120 PLAY=1 bash run_ghdl_tests.sh
```

### Generate a GIF Showcase
Run the non‑play path to build tests and a short GIF (frames/out.gif):
```
bash run_ghdl_tests.sh
```
This uses a fast functional renderer (raw RGB → `ffmpeg`) to keep generation quick.

### Tech Overview
- `vga_play_tb.vhd` — functional renderer: draws paddles/ball, reads controls from a file each frame, writes raw RGB24 frames to a stream path
- `play_controls.sh` — low‑latency keyboard→file bridge with TTL so holds feel natural (no TTY hacks inside the TB)
- `vga_controller.vhd` — timing‑accurate 640×480@60 VGA core (HSYNC/VSYNC), for verification
- `score_7seg.vhd` + `SevenSegController` — 4‑digit multiplexed 7‑segment display
- `input_controller.vhd` — debounced button sampling → paddle position

### File Map
- `vga_play_tb.vhd` — play TB (renderer)
- `play_controls.sh` — keyboard controls (HUD + low‑latency updates)
- `run_ghdl_tests.sh` — builds tests; with `PLAY=1` starts live play
- `vga_controller.vhd` / `vga_tb.vhd` — accurate VGA timing + TB
- `score_7seg.vhd`, `7seg.vhd`, `*_tb.vhd` — score display logic + tests

### Notes
- Live preview prefers `ffplay`; if missing, it records to `frames/live.mp4`.
- If your terminal isn’t a TTY, use `play_controls.sh` in a real terminal emulator window.
- The playable TB prioritizes responsiveness over cycle accuracy. Use `vga_tb.vhd` for timing checks.

### Credits & License
Built for teaching and fun. Adapt freely for your lab/playground.

![Showcase](frames/out.gif)

