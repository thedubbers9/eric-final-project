### This file is used to generate random test cases for the CPU simulator.

import argparse
import random
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
    "NOP":    "NOP"
}

opcode_map_inv = {v: k for k, v in opcode_map.items()}

MIN_REG = 1
MAX_REG = 15  # Maximum value for register

MEM_SIZE = 1024 # 12-bit words. 

jump_targets = {}

## Generates a random instruction. Returns a binary string of 12 bits.
def generate_random_instruction(current_pc):
    opcode = random.choice(list(opcode_map.keys()))
    if opcode == "NOP":
        return ["101100010001"]
    elif opcode == "HALT":
        return None # don't include halt instruction in the test case.
    elif opcode == "LOAD":
        return [opcode_map[opcode] + format(random.randint(MIN_REG, MAX_REG), '04b') + format(random.randint(MIN_REG, MAX_REG), '04b')]
    elif opcode == "JUMP":
        ## If the either of the next three instructions is the target address of a prior jump instruction, skip this instruction. We need the setup instructions before the jump instruction.
        if jump_targets.get(current_pc + 1) == 1 or jump_targets.get(current_pc + 2) == 1 or jump_targets.get(current_pc + 3) == 1:
            return None

        rand_shift_max = 2
        
        rand_reg = random.randint(MIN_REG, MAX_REG) # REG to store jump addr 
        rand_shift_reg = random.randint(MIN_REG, MAX_REG) # REG to store the shift amount.
        rand_val = random.randint(0, 15) 
        rand_shift = random.randint(0, rand_shift_max) 

    
        attempts = 0
        target_addr = (rand_val<<rand_shift) + current_pc + 1 + 3 # +3 because the actual jump instruction is 3 instructions away from the current pc.
        while target_addr >= MEM_SIZE:
            rand_shift_max+=1
            rand_val = random.randint(0, 15)
            rand_shift = random.randint(0, rand_shift_max)
            target_addr = (rand_val<<rand_shift) + current_pc + 1
            attempts += 1
            if attempts > 30:
                return None
        
        ## save the target address 
        jump_targets[target_addr] = 1

        return [ opcode_map["LI"] + format(rand_reg, '04b') + format(rand_val, '04b'), 
                 opcode_map["LI"] + format(rand_shift_reg, '04b') + format(rand_shift, '04b'),
                 opcode_map["SL"] + format(rand_reg, '04b') + format(rand_shift_reg, '04b'),
            opcode_map[opcode] + format(rand_reg, '04b') + "0000"]
    elif opcode == "LOAD" or opcode == "STOREL" or opcode == "STOREU":
        rand_shift_max = 2
        
        rand_reg = random.randint(MIN_REG, MAX_REG) # REG to store mem addr 
        rand_val = random.randint(0, 15) 
        rand_shift = random.randint(0, 6) 

        rand_dest_reg = random.randint(MIN_REG, MAX_REG)

        return [ opcode_map["LI"] + format(rand_reg, '04b') + format(rand_val, '04b'), 
                 opcode_map["SL"] + format(rand_reg, '04b') + format(rand_shift, '04b'),
            opcode_map[opcode] + format(rand_dest_reg, '04b') + format(rand_reg, '04b')]
    elif opcode == "BRANCH":
        ## skip the branch instruction if the current pc is within 64 instructions of max mem size.
        if current_pc >= MEM_SIZE - 64:
            return None
        rand_offset = random.randint(0, 63)  # Random offset for branch instruction

        # note the target address of the branch instruction so we don't put a jump sequence there. 
        target_addr = current_pc + rand_offset + 1
        if target_addr >= MEM_SIZE:
            return None
        jump_targets[target_addr] = 1

        branch_type = random.choice(['0', '1'])
        return [opcode_map[opcode] + branch_type + format(rand_offset, '07b')]
    else:
        return [opcode_map[opcode] + format(random.randint(MIN_REG, MAX_REG), '04b') + format(random.randint(0, 15), '04b')]

def instruction_disassemble(machine_instruction):
    # convert hex to binary
    machine_instruction = format(int(machine_instruction, 16), '012b')
    if machine_instruction == "101100010001":
        return "NOP"
    elif machine_instruction == "000000000000":
        return "HALT"
    
    opcode = machine_instruction[0:4]

    opcode_text = opcode_map_inv[opcode]

    if opcode_text == "BRANCH":
        branch_type = machine_instruction[4:5]
        if branch_type == '0':
            branch_type_char = "z"
        else:
            branch_type_char = "p"
        offset = machine_instruction[5:]
        return f"{opcode_text}{branch_type_char} {int(offset, 2)}"
    elif opcode_text == "JUMP":
        Rd = machine_instruction[4:8]
        return f"{opcode_text} R{int(Rd, 2)}"
    else:
        Rd = machine_instruction[4:8]
        Rs = machine_instruction[8:12]
        if opcode_text == "LI":
            return f"{opcode_text} R{int(Rd, 2)}, {int(Rs, 2)}"
        return f"{opcode_text} R{int(Rd, 2)}, R{int(Rs, 2)}"


def main():
    parser = argparse.ArgumentParser(description="Generate random test cases for CPU simulator.")
    parser.add_argument("-n", "--num_instructions", type=int, default=1000, help="Number of instructions to generate")
    parser.add_argument("-o", "--output_file", default="random_test.asm", help="Output file name")
    parser.add_argument("-b", "--batch_quantity", type=int, default=1, help="Number of test cases to generate")
    args = parser.parse_args()

    for i in range(args.batch_quantity):
        output_file_name = f"{args.output_file}_{i}.asm"
        generate_test_case(args.num_instructions, output_file_name)


def generate_test_case(num_instructions, output_file_name):
    
    if num_instructions < 16:
        raise ValueError("Number of instructions must be at least 16.")
    
    instructions = []

    current_pc = 0  # Initialize the program counter

    ## set every register to 0. 
    for i in range(16):
        instructions.append(opcode_map["LI"] + format(i, '04b') + "0000")
        current_pc += 1

    for i in range(num_instructions):
        next_instructions = generate_random_instruction(current_pc)
        if next_instructions is None:
            continue  # Skip the HALT instruction
        instructions.extend(next_instructions)
        current_pc += len(next_instructions)
        #print(f"Current PC: {current_pc}, Instruction: {next_instructions}")

    # trim any instructions if there are more than 1023 instructions.
    if len(instructions) > MEM_SIZE - 1:
        instructions = instructions[:MEM_SIZE - 1]

    instructions.append("000000000000")  # Add a HALT instruction at the end
    

    ## convert the instructions to hex format
    for i in range(len(instructions)):
        instructions[i] = format(int(instructions[i], 2), '03X')

    ## convert the instructions to assembly format
    for i in range(len(instructions)):
        instructions[i] = instruction_disassemble(instructions[i])


    # Write the instructions to a file
    with open(output_file_name, "w") as f:
        for instr in instructions:
            f.write(instr + "\n")

    print(f"Generated {num_instructions} random instructions and saved to {output_file_name}.")



if __name__ == "__main__":
    main()


