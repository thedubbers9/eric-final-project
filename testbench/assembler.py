import argparse


opcode_map = {
    "HALT":   "0000",
    "LOAD":   "0001",
    "JUMP":   "0010",
    "BRANCHZ": "00110",
    "BRANCHP": "00111",
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


def parse_opcode(opcode):
    opcode = opcode.upper()
    # remove any leading/trailing whitespace
    opcode = opcode.strip()
    
    mapped_opcode = opcode_map.get(opcode, None)

    if mapped_opcode is None:
        print(f"Error: Unknown opcode '{opcode}'")
        exit(1)
    return mapped_opcode


def assemble_instruction(instruction):
    # splice the instruction into two parts based on the first space
    debug_print(f"assembling instruction: {instruction}")
    parts = instruction.split(' ', 1)
    opcode = parts[0]
    the_rest = parts[1] if len(parts) > 1 else ''

    opcode_bin = parse_opcode(opcode)

    if opcode_bin == opcode_map["HALT"]:
        return "000000000000"
    
    if opcode_bin == opcode_map["NOP"]:
        return "101100010001"
    
    if opcode_bin == opcode_map["JUMP"]:
        Rd = the_rest.strip()
        if len(the_rest) == 0:
            print(f"Error: Invalid instruction format: {instruction}")
            exit(1)
        Rd = Rd.split('#')[0].strip()  # Remove comment if present
        Rd = Rd[1:]
        Rd_bin = format(int(Rd), '04b')
        return opcode_bin + Rd_bin + "0000"
    
    if opcode_bin == opcode_map["BRANCHZ"] or opcode_bin == opcode_map["BRANCHP"]:
        imm = the_rest.strip()
        if len(the_rest) == 0:
            print(f"Error: Invalid instruction format: {instruction}")
            exit(1)
        imm = imm.split('#')[0].strip()
        imm_bin = format(int(imm), '07b')
        return opcode_bin + imm_bin
    
    # The rest of the instructions are in the form of "opcode Rd, Rs"
    if ',' not in the_rest:
        print(f"Error: Invalid instruction format: {instruction}")
        exit(1)
    
    # string might still include comment after
    if '#' in the_rest:
        the_rest = the_rest.split('#')[0].strip()
    the_rest = the_rest.strip()

    Rd, Rs = map(str.strip, the_rest.split(','))
    Rd = Rd.strip()
    Rs = Rs.strip()

    if len(Rd) == 0 or len(Rs) == 0:
        print(f"Error: Invalid instruction format: {instruction}")
        exit(1)

    # Remove the leading 'R' from Rd and Rs
    Rd = Rd[1:]
    if (opcode_bin == opcode_map["LI"]):
        if Rs[0] == '-':
            Rd_bin = format(int(Rd), '04b')
            imm_val = 16 - int(Rs[1:])
            imm_bin = format(imm_val, '04b')
            return opcode_bin + Rd_bin + imm_bin
    else:
        Rs = Rs[1:]

    Rd_bin = format(int(Rd), '04b')
    Rs_bin = format(int(Rs), '04b')

    return opcode_bin + Rd_bin + Rs_bin

def assemble_file(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()

        output = []

        for line in lines:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            line_asm = assemble_instruction(line)

            # convert to hex
            line_hex = format(int(line_asm, 2), '03X')
            output.append(line_hex)

        return output

    

def main():
    parser = argparse.ArgumentParser(description="Simple Assembler for Custom ISA")
    parser.add_argument("input_file", help="Path to assembly code input file")
    parser.add_argument("-o", "--output", help="Path to output file (default: input_file.hex)", default=None)
    parser.add_argument("-d", "--debug", action="store_true", help="Enable debug mode")
    args = parser.parse_args()

    output = assemble_file(args.input_file)

    if args.debug:
        global debug
        debug = True
        debug_print("Debug mode enabled")

    # write assembled instructions to output file
    output_file = args.input_file.replace('.asm', '.hex')
    if args.output:
        output_file = args.output
    with open(output_file, 'w') as f:
        for instruction in output:
            f.write(instruction + '\n')

if __name__ == "__main__":
    main()