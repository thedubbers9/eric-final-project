import os
import logging
import random
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import *

# Determinism
random.seed(42)

MAX_CYCLES = 100000
CLK_PERIOD = 10  # ns

@cocotb.test()
async def basic_test(dut):
    print("============== STARTING TEST ==============")

    # Run the clock
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD, units="ns").start())

    # Since our circuit is on the rising edge,
    # we can feed inputs on the falling edge
    # This makes things easier to read and visualize
    await FallingEdge(dut.clk)

    # Reset the DUT
    dut.rst.value = True
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.rst.value = False

    try:
        await First(RisingEdge(dut.halt), Timer(CLK_PERIOD*MAX_CYCLES, units="ns"))
    except Exception:
        print("Timeout reached before halt signal.")
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)

    # for i in range(MAX_CYCLES):
    #     await FallingEdge(dut.clk)
    #     print (f"read_write: {dut.read_write.value} at time {} ns")
    #     if dut.halt.value == 1:
    #         print("Halt signal received.")
    #         break
    #     elif dut.read_write.value == 0:
    #         if dut.write_commit == 0:
    #             print (f"WRITE: ADDRESS: {dut.addr_data.value} at time {dut.clk.value} ns")
    #         else:
    #             print (f"WRITE COMMIT: DATA: {dut.addr_data.value} at time {dut.clk.value} ns")

    # await FallingEdge(dut.clk)
    # await FallingEdge(dut.clk)

