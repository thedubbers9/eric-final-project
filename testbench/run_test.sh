#!/bin/bash
## make sure we have the right number of arguments
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <test_file> <output_file_mem_dump> <output_trace_dump>"
    exit 1
fi

### I asked chatgpt how to add an argument in the middle of a sed command, and it said to use | instead of / for the delimiters.
sed -i "s|\$readmemh(\".*\", memory_array)|\$readmemh(\"$1\", memory_array)|" ../src/memory.sv
sed -i "s|\$writememh(\".*\", memory_array)|\$writememh(\"$2\", memory_array)|" ../src/memory.sv

### write a sed command to replace the file name in this string in ../src/cpu_hier.sv with $3 $fopen("prog_trace.txt", "w");
sed -i "s|\$fopen(\".*\", \"w\")|\$fopen(\"$3\", \"w\")|" ../src/cpu_hier.sv

# then, run the testbench
make -Bf testbench.mk