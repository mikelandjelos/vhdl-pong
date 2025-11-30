#!/bin/bash

# Clean previous build
rm -rf work-obj
mkdir -p work-obj

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
echo "All tests completed!"
echo "========================================="
