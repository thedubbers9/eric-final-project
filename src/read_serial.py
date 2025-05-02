import serial.tools.list_ports
import serial, random
from tqdm import tqdm
import sys
import time

# if None, tries to auto-find serial port
SERIAL_PORT = None

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




while True:
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


    # Write data periodically
    if time.time() - last_write_time > write_interval:
        # Example data to send: [START_BYTE, 0x01, 0x02, 0x03, 0x04, STOP_BYTE]
        example_data = "010101010101"
        if count %2 == 1:
            example_data = "101010101010"
            #write_data([START_BYTE, 0x32, 0x23, 0x32, 0x23, STOP_BYTE])
            #write_data([START_BYTE, 0x33, 0x22, 0x33, 0x22, STOP_BYTE])
        count+=1

        if count == 3:
            write_data([START_BYTE, 0xF6, 0xF6, 0xF6, 0xF6, STOP_BYTE])
        else:
            write_mem_addr(500, example_data)
        
        last_write_time = time.time()
