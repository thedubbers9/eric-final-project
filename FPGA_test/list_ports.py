import serial.tools.list_ports

ports = serial.tools.list_ports.comports()

for x in ports:
    vid = "None" if x.vid is None else f"{x.vid:04x}"
    pid = "None" if x.pid is None else f"{x.pid:04x}"

    print(f"- {x.device}")
    print(f"  - Description:", x.description)
    print(f"  - Int/Loc", x.interface, x.location)
    print(f"  - VID/PID: {vid}:{pid}")
    print(f"  - Manufacturer:", x.manufacturer)
    print(f"  - Product:", x.product)
    print(f"  - Serial:", x.serial_number)
    print()
