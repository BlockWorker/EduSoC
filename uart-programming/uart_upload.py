from crc import Calculator, Configuration
import serial
import serial.tools.list_ports as lp
import sys


def send_data(port, addr, data, calc, disp=False):
    size = len(data) // 4
    checksum = calc.checksum(data).to_bytes(4, 'little')

    message = addr.to_bytes(4, 'little') + size.to_bytes(4, 'little') + data + checksum

    port.reset_input_buffer()
    port.reset_output_buffer()

    if disp:
        print('Writing', size * 4, 'bytes...')
    port.write(message)

    received = port.read()

    if received == b'\x59':
        port.reset_input_buffer()
        return True
    elif received == b'\x23':
        print('CRC mismatch, data corruption is possible. Please retry transmission.')
    elif received == b'\xe0':
        print('Receiver error. Please manually reset the Arty-S7 board and try again.')
    else:
        print('Unknown response from receiver. Please manually reset the Arty-S7 board and try again.')

    port.reset_input_buffer()
    return False


def read_file(filename):
    data = b''

    print('Loading file...')
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

    return data


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

args = sys.argv
addr = 0
filename = ''

if len(args) < 2:
    addr_str = input('Address: 0x')
    addr = int(addr_str, 16)
    filename = input('File: ')
elif len(args) < 3:
    addr = 0x1C000000
    filename = args[1]
else:
    addr = int(args[1], 16)
    filename = args[2]

file_data = read_file(filename)

if addr == 0x1C000000:
    print('Writing to start of RAM: Performing programming routine')
    if not send_data(port, 0x1B000000, 0x0000000E.to_bytes(4, 'little'), calc):  # reset SoC
        exit(1)
    if not send_data(port, 0x1B000000, 0x0000000B.to_bytes(4, 'little'), calc):  # halt core and hold in reset
        exit(1)
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
    if not send_data(port, 0x1B000000, 0x00010008.to_bytes(4, 'little'), calc):  # allow core to run, set control flag to indicate programmed RAM
        exit(1)
    print('Programming complete.')
elif addr == 0x1A000000:
    print('Writing to start of Boot ROM: Performing programming routine')
    if not send_data(port, 0x1B000000, 0x0000000E.to_bytes(4, 'little'), calc):  # reset SoC
        exit(1)
    if not send_data(port, 0x1B000000, 0x0000000B.to_bytes(4, 'little'), calc):  # halt core and hold in reset
        exit(1)
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
    if not send_data(port, 0x1B000000, 0x00000008.to_bytes(4, 'little'), calc):  # allow core to run, no control flag
        exit(1)
    print('Programming complete.')
else:
    print('Writing to non-standard address (not programming)')
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
