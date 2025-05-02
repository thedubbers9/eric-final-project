#!/bin/sh

set -e

rm -r build || true

mkdir build

yosys -p "read_verilog -sv ../src/alu.sv ../src/branch_jump.sv ../src/chip.sv ../src/control.sv ../src/cpu_on_fpga.sv ../src/decode.sv ../src/ec_pipe_reg.sv ../src/execute.sv ../src/fe_pipe_reg.sv ../src/fetch.sv ../src/flags_register.sv ../src/memory_fpga.sv ../src/register_file.sv; synth_ecp5 -json build/synthesis.json -top cpu_on_fpga -noflatten"

nextpnr-ecp5 --12k --json build/synthesis.json --lpf constraints.lpf --textcfg build/pnr_out.config --freq 25

ecppack --compress build/pnr_out.config build/bitstream.bit

fujprog build/bitstream.bit
