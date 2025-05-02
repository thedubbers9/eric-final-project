import argparse
import serial.tools.list_ports
import serial, random
from tqdm import tqdm
import sys
import time

# if None, tries to auto-find serial port
SERIAL_PORT = None


parser = argparse.ArgumentParser(description="loads a .hex file onto the FPGA board's memory, runs the cpu, and reads back the memory.")
parser.add_argument("-i", "--input_hex", default=None, help="Path to .hex machine code input file")
parser.add_argument("-o", "--output_hex", default=None, help="Path to .hex file to write the output memory state to")

args = parser.parse_args()

if args.input_hex is None:
    print("ERROR: No input hex file provided")
    sys.exit(1)

if args.output_hex is None:
    print("ERROR: No output hex file provided")
    sys.exit(1)


ports = serial.tools.list_ports.comports()
port = [x for x in ports if "ULX3S" in str(x.description)+str(x.product)]

if SERIAL_PORT is None:
    if len(port) == 0:
        print("ERROR: No ULX3S serial ports found")
        sys.exit(1)
    elif len(port) > 1:
        print("ERROR: Multiple ULX3S devices found")
        sys.exit(1)
    else:
        SERIAL_PORT = port[0].device

port = [x for x in ports if x.device == SERIAL_PORT]

if len(port) != 1:
    print(f"ERROR: port {SERIAL_PORT} not found")
    sys.exit(1)

print(f"Found port {SERIAL_PORT} with description '{port[0].description}'")

print("Opening serial port. Note that this will PREVENT using fujprog until this script is killed")
ser = serial.Serial(SERIAL_PORT, 115200, timeout=0)

time.sleep(1)
# flush out the port
ser.read(999)

print("Ready...")

START_BYTE = 0xF5
STOP_BYTE = 0xFA

last = 0
last_time = 0

buf = bytearray()

# Function to write data to the serial port
def write_data(data):

    ser.write(bytearray(data))
    print(f"Sent data: {data}")

# Example: Writing data periodically
write_interval = 5  # seconds
last_write_time = time.time()

count = 0

def write_mem_addr(addr, word):
    ''' addr: int address to write to (0-1023)
    word: 12-bit word as a string of binary characters. E.g. "000000000000" (12 bits) '''

    ## we can't have a 1 in the MSB of any of the bytes to avoid getting confused with the start/stop bytes


    byte0 = (addr >> 5) & 0x1F # upper 5 bits of address.
    byte1 = addr & 0x1F # lower 5 bits of address
    byte2 = int(word[:6], 2) # upper 6 bits of word
    byte3 = int(word[6:], 2) # lower 6 bits of word

    print(f"Writing to address {addr}: {word}")
    print(f"Bytes: {byte0:08b} {byte1:08b} {byte2:08b} {byte3:08b}")

    data = [START_BYTE, byte0, byte1, byte2, byte3, STOP_BYTE]

    write_data(data)

def get_data_from_serial(b):
    ''' b: byte array to read from serial port '''
    if b[0] != START_BYTE:
        print("ERROR: no Start byte")
        return None
    
    if b[-1] != STOP_BYTE:
        print("ERROR: Stop byte not present")
        return None

    # Extract the data between the start and stop bytes
    data = b[1:-1]

    # do the reverse of the write_mem_addr function to get the address and word back
    addr = (data[0] << 5) | data[1] 
    word = (data[2] << 6) | data[3]

    return addr, word


instructions = []
addr = 0
## open up a file to read lines from 
with open(args.input_hex, "r") as f:
    for line in f.readlines():
        line = line.strip()
        if len(line) == 0:
            continue

        # convert the hex string to a binary string of length 12
        word = bin(int(line, 16))[2:].zfill(12)
        print(f"Writing to address {addr}: {word}")
        time.sleep(0.1)
        write_mem_addr(addr, word)
        addr += 1

time.sleep(8)

## send command to read data back from memory. 
write_data([0xF6, 0xF6, 0xF6, 0xF6, 0xF6, 0xF6])

result_mem = {}

done = False
start_time = time.time()
while not done and time.time() - start_time < 30:

    # Read data
    buf += ser.read(100)

    while len(buf) and buf[0] != START_BYTE:
        buf = buf[1:]

    while len(buf) >= 6:
        b = buf[:6]
        buf = buf[6:]

        if b[0] != START_BYTE or b[5] != STOP_BYTE:
            continue

        #print all bytes in hex
        print("Received data: ", end="")
        for byte in b:
            print(f"{byte:02X} ", end="")

        addr, word = get_data_from_serial(b)
        if addr is not None and word is not None:
            print(f"Address: {addr}, Word: {word:012b}")
            result_mem[addr] = word
            if addr == 1023:
                done = True
                break


## write the data to a file
with open(args.output_hex, "w") as f:
    for addr in range(1024):
        if addr in result_mem:
            f.write(f"{result_mem[addr]:03X}\n")
        else:
            f.write("000\n")
