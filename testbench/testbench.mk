TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(shell find $(shell pwd)/../src/ -maxdepth 1 -name "*.sv" ! -name "uart.sv" ! -name "cpu_on_fpga.sv" ! -name "memory_fpga.sv")
TOPLEVEL = cpu_hier
MODULE = testbench
SIM = verilator
WAVES = 1
EXTRA_ARGS += --trace --trace-structs -Wno-fatal -I$(abspath ../src)
include $(shell cocotb-config --makefiles)/Makefile.sim
