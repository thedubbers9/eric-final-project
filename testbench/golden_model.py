### This file takes in the assembler output and outputs the final memory state after the program has run.

import argparse
import os

MAX_INSTRUCTIONS = 100000

opcode_map = {
    "HALT":   "0000",
    "LOAD":   "0001",
    "JUMP":   "0010",
    "BRANCH": "0011",
    "LI":     "0100",
    "NOT":    "0101",
    "STOREL": "0110",
    "STOREU": "0111",
    "ADD":    "1000",
    "SUB":    "1001",
    "AND":    "1010",
    "OR":     "1011",
    "XOR":    "1100",
    "SL":     "1101",
    "SRL":    "1110",
    "SRA":    "1111",
    "NOP":    "NOP",
}

debug = False

def debug_print(msg):
    if debug:
        print(msg)

def bit_add(val1, val2):
    ## wrap around should be handled because we limiting to 12 bits.
    int_result = int(val1, 2) + int(val2, 2)
    if int_result >= 4096: # 2^12 = 4096
        int_result = int_result - 4096
    result = format(int_result, '012b')
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def bit_not(val1):
    result = ''
    for bit in val1:
        if bit == '0':
            result += '1'
        else:
            result += '0'
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result


def bit_sub(val1, val2):
    '''
    result = val1 - val2
    '''
    debug_print(f"Bit sub: {val1}, {val2}")
    not_val2 = bit_not(val2)
    debug_print(f"Not val2: {not_val2}")
    not_val2_plus1 = bit_add(not_val2, '000000000001')
    debug_print(f"Not val2 + 1: {not_val2_plus1}")
    result = bit_add(val1, not_val2_plus1)
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def bit_and(val1, val2):
    result = ''
    for i in range(len(val1)):
        if val1[i] == '1' and val2[i] == '1':
            result += '1'
        else:
            result += '0'
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def bit_or(val1, val2):
    result = ''
    for i in range(len(val1)):
        if val1[i] == '1' or val2[i] == '1':
            result += '1'
        else:
            result += '0'
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def bit_xor(val1, val2):
    result = ''
    for i in range(len(val1)):
        if (val1[i] == '1' and val2[i] == '0') or (val1[i] == '0' and val2[i] == '1'):
            result += '1'
        else:
            result += '0'
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def shift_left(val1, val2):
    '''
    Shift val 1 left by val2 bits
    '''
    debug_print(f"Shift left: {val1}, {val2}")
    if val2 == '000000000000':
        result = val1
    else:
        shift_amount = int(val2, 2)
        debug_print(f"Shift amount: {shift_amount}")
        if shift_amount >= 12:
            result = '0' * 12
        else:
            result = val1[shift_amount:] + '0' * shift_amount
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def shift_right_logical(val1, val2):
    '''
    Shift val 1 right by val2 bits
    '''
    debug_print(f"Shift right logical: {val1}, {val2}")
    if val2 == '000000000000':
        result = val1
    else:
        shift_amount = int(val2, 2)
        debug_print(f"Shift amount: {shift_amount}")
        if shift_amount >= 12:
            result = '0' * 12
        else:
            result = '0' * shift_amount + val1[:-shift_amount]
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result

def shift_right_arithmetic(val1, val2):
    '''
    Shift val 1 right by val2 bits
    '''
    debug_print(f"Shift right arithmetic: {val1}, {val2}")
    if val2 == '000000000000':
        result = val1
    else:
        shift_amount = int(val2, 2)
        debug_print(f"Shift amount: {shift_amount}")
        if shift_amount >= 12:
            result = val1[0] * 12
        else:
            result = val1[0] * shift_amount + val1[:-shift_amount]
    assert len(result) == 12, f"Result is not 12 bits: {result}"
    return result


class CPU:
    def __init__(self, memory):
        self.regs = ["000000000000"] * 16      
        self.memory =  ["000000000000"] * 1024 # Mem is stored as binary strings
        self.pc = 0             
        self.z_flag = 0       
        self.p_flag = 0   
        self.instruction_count = 0
        self.trace = []

        # fill in mem with init vals
        for i in range(len(memory)):
            self.memory[i] = memory[i]

    def update_reg(self, reg_num_str, value, curr_inst, curr_pc):
        reg_num = int(reg_num_str, 2)
        if reg_num < 0 or reg_num >= len(self.regs):
            raise ValueError(f"Invalid register number: {reg_num}")
        self.regs[reg_num] = value
        self.trace.append(f"PC: {format(curr_pc, '04d')} Instr {format(int(curr_inst, 2), '03x')}: Write to Reg [{format(reg_num, '02d')}] = {value}")

    def run(self):
        
        while True:
            if self.instruction_count >= MAX_INSTRUCTIONS:
                print("Max instructions reached in golden model. Halting.")
                break

            if self.pc >= len(self.memory):
                self.pc = self.pc % len(self.memory)

            debug_print(f"PC: {self.pc} Instruction: {self.memory[self.pc]}")
            # create a debug print for the registers
            reg_str = ""
            for i in range(len(self.regs)):
                reg_str += f"R{i}: {self.regs[i]} "
            debug_print(f"Registers: {reg_str}")
            curr_inst = self.memory[self.pc]
            curr_pc = self.pc
            self.pc += 1
            self.instruction_count += 1
            opcode = curr_inst[:4]

            if opcode == opcode_map["HALT"]:
                break
            if curr_inst == "101100010001": # NOP instruction
                debug_print(f"NOP instruction: {curr_inst}")
                continue

            if opcode == opcode_map["JUMP"]:
                debug_print(f"Jump instruction: {curr_inst}")
                Rd = curr_inst[4:8]
                debug_print(f"Rd: {Rd}")
                jump_dist = int(self.regs[int(Rd, 2)],2)
                debug_print(f"Jump distance: {jump_dist}")
                self.pc = jump_dist + self.pc # self.pc is already incremented by 1
                continue

            if opcode == opcode_map["BRANCH"]:
                debug_print(f"Branch instruction: {curr_inst}, z_flag: {self.z_flag}, p_flag: {self.p_flag}")
                option = curr_inst[4]
                imm = curr_inst[5:]
                if option == '0':
                    if self.z_flag == 1:
                        self.pc = int(imm, 2) + self.pc # self.pc is already incremented by 1
                elif option == '1':
                    if self.p_flag == 1:
                        self.pc = int(imm, 2) + self.pc # self.pc is already incremented by 1
                continue

            Rd = curr_inst[4:8]


            if opcode == opcode_map["LI"]:
                debug_print(f"LI instruction: {curr_inst}, Rd: {Rd}")
                imm = curr_inst[8:]
                self.update_reg(Rd, 8 * "0" + imm, curr_inst, curr_pc)
                continue

            Rs = curr_inst[8:]

            ## All other instructions are in the same form

            if opcode == opcode_map["LOAD"]:
                debug_print(f"Load instruction: {curr_inst}, Rd: {Rd}, Rs: {Rs}")
                address = int(self.regs[int(Rs, 2)][2:], 2)  # ignore two MSBs
                debug_print(f"address: {address}")
                self.update_reg(Rd, self.memory[address], curr_inst, curr_pc)
                continue

            if opcode == opcode_map["STOREL"]:  # least significant 6 bits of Rd
                debug_print(f"StoreL instruction: {curr_inst}, Rd: {Rd}, Rs: {Rs}")
                val_to_store_LSBs = self.regs[int(Rd, 2)][6:]
                address = int(self.regs[int(Rs, 2)][2:], 2)
                debug_print(f"address: {address}")
                curr_val_MSBs = self.memory[address][:6]
                self.memory[address] = curr_val_MSBs + val_to_store_LSBs

                self.trace.append(f"PC: {format(curr_pc, '04d')} Instr {format(int(curr_inst, 2), '03x')}: Write to Mem [{format(address, '04d')}] = {val_to_store_LSBs}")
                continue

            if opcode == opcode_map["STOREU"]:  # most significant 6 bits of Rd
                debug_print(f"StoreU instruction: {curr_inst}, Rd: {Rd}, Rs: {Rs}")
                val_to_store_MSBs = self.regs[int(Rd, 2)][:6]
                debug_print(f"val_to_store_MSBs: {val_to_store_MSBs}")
                address = int(self.regs[int(Rs, 2)][2:], 2)
                debug_print(f"address: {address}")
                curr_val = self.memory[address]
                debug_print(f"curr_val: {curr_val}")
                curr_val_LSBs = curr_val[6:]
                self.memory[address] = val_to_store_MSBs + curr_val_LSBs

                self.trace.append(f"PC: {format(curr_pc, '04d')} Instr {format(int(curr_inst, 2), '03x')}: Write to Mem [{format(address, '04d')}] = {val_to_store_MSBs}")
                continue

            # These instructions set the flags
            if opcode == opcode_map["ADD"]:
                self.update_reg(Rd, bit_add(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["SUB"]:
                self.update_reg(Rd, bit_sub(self.regs[int(Rs, 2)], self.regs[int(Rd, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["AND"]:
                self.update_reg(Rd, bit_and(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["OR"]:
                self.update_reg(Rd, bit_or(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["XOR"]:
                self.update_reg(Rd, bit_xor(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["SL"]:
                result = shift_left(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)])
                debug_print(f"Shift left result: {result}")
                self.update_reg(Rd, result, curr_inst, curr_pc)
            elif opcode == opcode_map["SRL"]:
                self.update_reg(Rd, shift_right_logical(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["SRA"]:
                self.update_reg(Rd, shift_right_arithmetic(self.regs[int(Rd, 2)], self.regs[int(Rs, 2)]), curr_inst, curr_pc)
            elif opcode == opcode_map["NOT"]:
                self.update_reg(Rd, bit_not(self.regs[int(Rs, 2)]), curr_inst, curr_pc)

            debug_print(f"Rd: {Rd}, Rs: {Rs}, opcode: {opcode}")

            # Set the flags 
            if int(self.regs[int(Rd, 2)],2) == 0:
                self.z_flag = 1
            else:
                self.z_flag = 0

            if self.regs[int(Rd, 2)][0] == '0' and int(self.regs[int(Rd, 2)],2) > 0:
                self.p_flag = 1
            else:
                self.p_flag = 0

    def dump_memory(self):
        return self.memory
    
    def dump_trace(self):
        return self.trace

def run_golden_model(input_file):
    with open(input_file, 'r') as f:
        lines = f.readlines()

        initial_mem = []

        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue

            # read in hex and convert to binary
            line_val = format(int(line, 16), '012b')

            initial_mem.append(line_val)

        ## make a new CPU object
        cpu = CPU(initial_mem)
        cpu.run()

        return cpu.dump_memory(), cpu.dump_trace()




def main():
    parser = argparse.ArgumentParser(description="Golden Model for RISC-E ISA")
    parser.add_argument("input_file", help="Path to .hex machine code input file")
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    global debug
    debug = args.debug

    output, trace = run_golden_model(args.input_file)

    # create the output file name
    output_file = args.input_file.replace('.hex', '_golden_run_out.hex')
    output_trace_file = args.input_file.replace('.hex', '_golden_run_trace.trace')
    
    
    with open(output_file, 'w') as f:
        for line in output:
            hex = format(int(line, 2), '03X')
            f.write(hex + '\n')

    with open(output_trace_file, 'w') as f:
        for line in trace:
            f.write(line + '\n')

if __name__ == "__main__":
    main()
