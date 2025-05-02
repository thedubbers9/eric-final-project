#!/usr/bin/python3

import argparse
import os


def read_hex_file(filename):
    result = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            
            # convert out of hex
            line = int(line, 16)

            result.append(line)

    # if the result isn't 1024 lines, pad the end with 0s
    while len(result) < 1024:
        result.append(0)

    return result


def read_trace_file(filename):
    result = []
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            result.append(line)

    return result



def main():
    parser = argparse.ArgumentParser(description="assembles a .asm file to .hex, runs the golden model, and compares the output running the testbench against the design.")
    parser.add_argument("-asm", "--input_asm", default=None, help="Path to .asm assembly code input file (for single run)")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug mode")
    parser.add_argument("-b", "--batch_dir", default=None, help="Path to directory containing .asm files to run in batch mode (for batch run)") # optional param.
    parser.add_argument("-b2", "--batch_dir2", default=None, help="Path to 2nd directory containing .asm files to run in batch mode (for batch run)") # optional param.
    parser.add_argument("-e", "--emulation", action="store_true", help="Run the testbench on the FPGA board")
    args = parser.parse_args()

    if args.input_asm and args.batch_dir:
        print("Error: Please provide either an input file or a batch directory, not both.")
        exit(1)
    if not args.input_asm and not args.batch_dir:
        print("Error: Please provide either an input file or a batch directory.")
        exit(1)

    if args.batch_dir:
        results = {}
        # run in batch mode
        for filename in os.listdir(args.batch_dir):
            if filename.endswith('.asm'):
                input_asm = os.path.join(args.batch_dir, filename)
                print(f"Running testbench on {input_asm}")
                success = run_testbench(input_asm, args.debug)
                results[filename] = success
                print(f"Testbench run complete! success: {success}")
                print("========================================")

        if args.batch_dir2:
            for filename in os.listdir(args.batch_dir2):
                if filename.endswith('.asm'):
                    input_asm = os.path.join(args.batch_dir2, filename)
                    print(f"Running testbench on {input_asm}")
                    success = run_testbench(input_asm, args.debug)
                    results[filename] = success
                    print(f"Testbench run complete! success: {success}")
                    print("========================================")
        
        print("Batch run complete!")
        print("Results:")
        total_success, total_fail = 0, 0
        for filename, success in results.items():
            print(f"{filename}: {'PASS' if success else 'FAIL'}")
            if success:
                total_success += 1
            else:
                total_fail += 1
        
        print(f"Total Success: {total_success}")
        print(f"Total Fail: {total_fail}")

    elif args.emulation:
        ## run the testbench on the FPGA board
        print("Running testbench on FPGA board")
        run_testbench_fpga(args.input_asm)


    else:
        run_testbench(args.input_asm, args.debug)


def run_testbench(input_asm, debug):

    input_dir = os.path.dirname(input_asm)

    # create the run_results directory if it doesn't exist
    run_results_dir = os.path.join(input_dir, "run_results")
    if not os.path.exists(run_results_dir):
        os.makedirs(run_results_dir)

    ## path for assembled file
    assembled_file = os.path.join(run_results_dir, os.path.basename(input_asm).replace('.asm', '.hex'))

    ######### assemble the input file
    print(f"Assembling {input_asm} to {assembled_file}")
    os.system(f"python3 assembler.py {input_asm} -o {assembled_file}{' -d' if debug else ''}")
    print(f"Assembly complete!")

    ######## run the golden model
    print(f"Running golden model on {assembled_file}")
    os.system(f"python3 golden_model.py {assembled_file}{' -d' if debug else ''}")
    golden_output_hex = assembled_file.replace('.hex', '_golden_run_out.hex')
    golden_trace_file = assembled_file.replace('.hex', '_golden_run_trace.trace')
    print(f"Golden model run complete! Output: {golden_output_hex}")

    ####### run the testbench

    # create the output file name
    testbench_output_hex = assembled_file.replace('.hex', '_testbench_run_out.hex')
    testbench_trace_file = assembled_file.replace('.hex', '_testbench_run_trace.trace')

    print(f"Running testbench on {assembled_file}")
    os.system(f"bash run_test.sh {assembled_file} {testbench_output_hex} {testbench_trace_file}")
    print(f"Testbench run complete! Output: {testbench_output_hex}")


    ####### compare the two final MEM states
    golden_output_lines = read_hex_file(golden_output_hex)
    testbench_output_lines = read_hex_file(testbench_output_hex)

    mismatch_mem = False
    for i in range(len(golden_output_lines)):
        if golden_output_lines[i] != testbench_output_lines[i]:
            print(f"Final MEM Mismatch at line {i}: Golden Model: {golden_output_lines[i]} Testbench: {testbench_output_lines[i]}")
            mismatch_mem = True
            break

    if not mismatch_mem:
        print("All lines for final memory state match!")

    ######## compare the two trace files
    golden_trace_lines = read_trace_file(golden_trace_file)
    testbench_trace_lines = read_trace_file(testbench_trace_file)

    mismatch_trace = False
    num_lines_testbench = len(testbench_trace_lines)
    for i in range(len(golden_trace_lines)):
        if i >= num_lines_testbench:
            print("Testbench trace file is shorter than golden trace file.")
            mismatch_trace = True
            break
        if golden_trace_lines[i] != testbench_trace_lines[i]:
            print(f"TRACE Mismatch at line {i}: Golden Model: {golden_trace_lines[i]} Testbench: {testbench_trace_lines[i]}")
            mismatch_trace = True
            break

    if testbench_trace_lines != golden_trace_lines:
        print(f"The testbench trace file has {len(testbench_trace_lines)} lines, while the golden trace file has {len(golden_trace_lines)} lines.")
        mismatch_trace = True

    if not mismatch_trace:
        print("All lines for trace match!")

    if not mismatch_mem and not mismatch_trace:
        print("YAHOO! TEST PASSED!")

    return not (mismatch_mem or mismatch_trace)
    

if __name__ == "__main__":
    main()



def run_testbench_fpga(input_asm):

    input_dir = os.path.dirname(input_asm)

    # create the run_results directory if it doesn't exist
    run_results_dir = os.path.join(input_dir, "run_results")
    if not os.path.exists(run_results_dir):
        os.makedirs(run_results_dir)

    ## path for assembled file
    assembled_file = os.path.join(run_results_dir, os.path.basename(input_asm).replace('.asm', '.hex'))

    ######### assemble the input file
    print(f"Assembling {input_asm} to {assembled_file}")
    os.system(f"python3 assembler.py {input_asm} -o {assembled_file}{' -d' if debug else ''}")
    print(f"Assembly complete!")

    ######## run the golden model
    print(f"Running golden model on {assembled_file}")
    os.system(f"python3 golden_model.py {assembled_file}{' -d' if debug else ''}")
    golden_output_hex = assembled_file.replace('.hex', '_golden_run_out.hex')
    golden_trace_file = assembled_file.replace('.hex', '_golden_run_trace.trace')
    print(f"Golden model run complete! Output: {golden_output_hex}")

    ####### run the testbench

    # create the output file name
    testbench_output_hex = assembled_file.replace('.hex', '_testbench_run_out.hex')
    testbench_trace_file = assembled_file.replace('.hex', '_testbench_run_trace.trace')

    print(f"Running testbench on {assembled_file}")
    os.system(f"bash run_test.sh {assembled_file} {testbench_output_hex} {testbench_trace_file}")
    print(f"Testbench run complete! Output: {testbench_output_hex}")


    ####### compare the two final MEM states
    golden_output_lines = read_hex_file(golden_output_hex)
    testbench_output_lines = read_hex_file(testbench_output_hex)

    mismatch_mem = False
    for i in range(len(golden_output_lines)):
        if golden_output_lines[i] != testbench_output_lines[i]:
            print(f"Final MEM Mismatch at line {i}: Golden Model: {golden_output_lines[i]} Testbench: {testbench_output_lines[i]}")
            mismatch_mem = True
            break

    if not mismatch_mem:
        print("All lines for final memory state match!")

    ######## compare the two trace files
    golden_trace_lines = read_trace_file(golden_trace_file)
    testbench_trace_lines = read_trace_file(testbench_trace_file)

    mismatch_trace = False
    num_lines_testbench = len(testbench_trace_lines)
    for i in range(len(golden_trace_lines)):
        if i >= num_lines_testbench:
            print("Testbench trace file is shorter than golden trace file.")
            mismatch_trace = True
            break
        if golden_trace_lines[i] != testbench_trace_lines[i]:
            print(f"TRACE Mismatch at line {i}: Golden Model: {golden_trace_lines[i]} Testbench: {testbench_trace_lines[i]}")
            mismatch_trace = True
            break

    if testbench_trace_lines != golden_trace_lines:
        print(f"The testbench trace file has {len(testbench_trace_lines)} lines, while the golden trace file has {len(golden_trace_lines)} lines.")
        mismatch_trace = True

    if not mismatch_trace:
        print("All lines for trace match!")

    if not mismatch_mem and not mismatch_trace:
        print("YAHOO! TEST PASSED!")

    return not (mismatch_mem or mismatch_trace)