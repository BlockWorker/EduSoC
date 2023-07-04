from crc import Calculator, Configuration
import serial
import serial.tools.list_ports as lp


def send_file(port, addr, filename, calc):
    print('Loading file...')

    data = b''

    if filename.startswith('0x'):
        rawhex = filename[8:] + filename[6:8] + filename[4:6] + filename[2:4]
        data = bytes.fromhex(rawhex)
    else:
        with open(filename, 'r') as f:
            line = f.readline()
            while len(line) > 0:
                line = line.strip()
                if len(line) == 0:
                    continue
                while len(line) < 8:
                    line = '0' + line
                rawhex = line[6:] + line[4:6] + line[2:4] + line[:2]
                data += bytes.fromhex(rawhex)
                line = f.readline()

    while len(data) % 4 != 0:
        data += b'\0'

    size = len(data) // 4
    checksum = calc.checksum(data).to_bytes(4, 'little')

    message = addr.to_bytes(4, 'little') + size.to_bytes(4, 'little') + data + checksum

    port.reset_input_buffer()
    port.reset_output_buffer()

    print('Writing', size * 4, 'bytes...')
    port.write(message)

    received = port.read()
    print(received.hex())
    port.reset_input_buffer()


ports = list(lp.grep('0403:6010'))
port_info = None
if len(ports) == 0:
    print('Serial port not found. Please ensure Arty-S7 is connected and powered.')
    exit(1)
elif len(ports) == 1:
    port_info = ports[0]
else:
    highest_serial = -1
    port_options = []
    for p in ports:
        ser = int(p.serial_number, 16)
        if ser > highest_serial:
            highest_serial = ser
            port_options = [p]
        elif ser == highest_serial:
            port_options.append(p)
    if len(port_options) == 1:
        port_info = port_options[0]
    else:
        highest_loc = -1.0
        for po in port_options:
            loc = float(po.location[-3:])
            if loc > highest_loc:
                highest_loc = loc
                port_info = po

port = serial.Serial(port=port_info.device, baudrate=500000, timeout=2)

calc = Calculator(Configuration(32, 0x1EDC6F41, 0xFFFFFFFF, 0xFFFFFFFF, True, True))

while True:
    addr_str = input('Address: ')
    if addr_str == 'exit':
        break
    addr = int(addr_str, 16)
    filename = input('File: ')
    send_file(port, addr, filename, calc)
