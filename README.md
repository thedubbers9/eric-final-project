# 18-224/624 S25 Tapeout Template

# Final Project Submission Details 
  
1. Your design must synthesize at 30MHz but you can run it at any arbitrarily-slow frequency (including single-stepping the clock) on the manufactured chip. If your design must run at an exact frequency, it is safest to choose a lower frequency (i.e. 5MHz)
This design successfully synthesizes at 32MHz.

2. For your final project, we will ask you to submit some sort of testbench to verify your design. Include all relevant testing files inside the `testbench` repository
Done. 
  
3. For your final project, we will ask you to submit documentation on how to run/test your design, as well as include your project proposal and progress reports. Include all these files inside the `docs` repository
To test the design, go to src/ and then run bash test_all.sh.
  
4. Optionally, if you use any images in your documentation (diagrams, waveforms, etc) please include them in a separate `img` repository
N/A
  

5. Feel free to edit this file and include some basic information about your project (short description, inputs and outputs, diagrams, how to run, etc). An outline is provided below

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

## How to Test

Connect the chip to the host FPGA. 
