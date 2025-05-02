#!/bin/sh

## chapgpt use: I asked it how to get a list of .sv files in the current dir from ls and it told me to use tr '\n' ' '.

set -e

rm -r build || true

mkdir build

yosys -p "read_verilog -sv alu.sv branch_jump.sv chip.sv control.sv cpu_on_fpga.sv decode.sv ec_pipe_reg.sv execute.sv fe_pipe_reg.sv fetch.sv flags_register.sv memory_fpga.sv register_file.sv; synth_ecp5 -json build/synthesis.json -top cpu_on_fpga -noflatten"

nextpnr-ecp5 --12k --json build/synthesis.json --lpf constraints.lpf --textcfg build/pnr_out.config --freq 25

ecppack --compress build/pnr_out.config build/bitstream.bit

fujprog build/bitstream.bit
