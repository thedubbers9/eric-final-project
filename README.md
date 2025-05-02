# 18-224/624 S25 Tapeout Template

# Final Project Submission Details 
  
1. Your design must synthesize at 30MHz but you can run it at any arbitrarily-slow frequency (including single-stepping the clock) on the manufactured chip. If your design must run at an exact frequency, it is safest to choose a lower frequency (i.e. 5MHz)
This design successfully synthesizes at 32MHz (based on output file from flow on github)

2. For your final project, we will ask you to submit some sort of testbench to verify your design. Include all relevant testing files inside the `testbench` repository
These files are in the testbench directory. 
  
3. For your final project, we will ask you to submit documentation on how to run/test your design, as well as include your project proposal and progress reports. Include all these files inside the `docs` repository
To test the design, go to src/ and then run bash test_all.sh. You will need to be in an OSS-CAD environment (following 18-224 setup)
To view the waveforms, run bash view_waves.sh

You can write your own testcases in assembly and then run them using automated_test.py -asm <file_name>

To run a test on the fpga, program the fpga. Go to testbench directory, run build.sh, make sure the FPGA is programmed, and then run automated_test.py -asm tests/handwritten_tests/add_test.asm -e


# Final Project

## RISC-E

This is a very basic microprocessor with a similar level of complexity as the intel 4004. 

## IO

All 12 inputs and outputs from the chip will be connected the memory (which will be on the FPGA). 

| Name          | Dir   | Width | Purpose for Read      | Purpose for Write          |
|---------------|-------|-------|-----------------------|----------------------------|
| addr_data     | in    | 10    | Addr                  | Cycle1: addr, C2: data     |
| read_write    | in    | 1     | Read when == 1        | Write when == 0            |
| write_commit  | in    | 1     | Must be zero          | Signifies 2nd cyc of write |
| mem_result    | out   | 12    | Read Result           | X                          |

*Direction is from memory’s perspective
If read_write and write_commit are both one, this indicates a HALT condition (HALT instruction reached). 

## How to Test after recieving the chip

Connect the chip to the host FPGA. Edit the cpu_on_fpga.sv file to connect to the actual cpu chip instead of the chip running on the FPGA. Based on the maximum possible clock speed that the CPU chip itself can run at, use a PLL to generate the appropriate clock frequency for the system. Operation of the testbench should otherwise be the same. The existing UART connection to the PC will still work to load tests into the FPGA memory and read out the final memory state.
