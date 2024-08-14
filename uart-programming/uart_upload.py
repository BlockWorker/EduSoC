############################################
#
# EduSoC UART upload script
# Alexander Kharitonov
# University of Stuttgart, ITI
#
# Designed for the Arty S7 board.
# Loads a .mem file (32 bits per entry, one entry per line) and writes it to a given SoC address over UART.
# For writes to the start of RAM or Boot ROM, performs additional steps for SoC reset and programming.
#
# Usage:
#   python uart_upload.py
#       Interactive mode, asks user for destination address and source mem file.
#   python uart_upload.py <file path>
#       Reads the given mem file and writes it to the start of RAM (0x1C000000), with steps to reset/program the SoC.
#   python uart_upload.py <file path> <hex address>
#       Reads the given mem file and writes it to the given address.
#
# Required packages: pyserial, crc
#
############################################

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
            if len(line) == 0:  # ignore empty/whitespace lines
                continue
            while len(line) < 8:  # zero pad incomplete values
                line = '0' + line
            rawhex = line[6:] + line[4:6] + line[2:4] + line[:2]  # we need little endian byte order
            data += bytes.fromhex(rawhex)
            line = f.readline()

    while len(data) % 4 != 0:  # pad out data to a multiple of 4 bytes (should already be one, but just to be sure)
        data += b'\0'

    return data


ports = list(lp.grep('0403:6010'))  # look for correct vendor/product ID (FTDI dual USB-to-UART, used on the Arty S7)
port_info = None
if len(ports) == 0:
    print('Serial port not found. Please ensure Arty-S7 is connected and powered.')
    exit(1)
elif len(ports) == 1:  # only one found (should theoretically not happen, since dual converter): use that
    port_info = ports[0]
else:
    highest_serial = -1  # more than one found: try to look for the highest serial number first (works in Windows)
    port_options = []
    for p in ports:
        ser = int(p.serial_number, 16)
        if ser > highest_serial:
            highest_serial = ser
            port_options = [p]
        elif ser == highest_serial:
            port_options.append(p)
    if len(port_options) == 1:
        port_info = port_options[0]  # pick the highest serial number
    else:
        highest_loc = -1.0  # multiple with equal highest serial: look for highest "location" number (needed for Linux)
        for po in port_options:
            loc = float(po.location[-3:])
            if loc > highest_loc:
                highest_loc = loc
                port_info = po

port = serial.Serial(port=port_info.device, baudrate=500000, timeout=2)

calc = Calculator(Configuration(32, 0x1EDC6F41, 0xFFFFFFFF, 0xFFFFFFFF, True, True))  # CRC-32C calculator

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
    filename = args[1]
    addrstr = args[2]
    if addrstr.startswith('0x'):
        addrstr = addrstr[2:]
    addr = int(addrstr, 16)

file_data = read_file(filename)

if addr == 0x1C000000:
    print('Writing to start of RAM: Performing programming routine')
    if not send_data(port, 0x1B000004, 0x00000004.to_bytes(4, 'little'), calc):  # reset SoC
        exit(1)
    if not send_data(port, 0x1B000004, 0x00000002.to_bytes(4, 'little'), calc):  # hold core in reset
        exit(1)
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
    if not send_data(port, 0x1B000004, 0x00010000.to_bytes(4, 'little'), calc):  # set control flag for programmed RAM
        exit(1)
    if not send_data(port, 0x1B000008, 0x00000002.to_bytes(4, 'little'), calc):  # allow core to run
        exit(1)
    print('Programming complete.')
elif addr == 0x1A000000:
    print('Writing to start of Boot ROM: Performing programming routine')
    if not send_data(port, 0x1B000004, 0x00000004.to_bytes(4, 'little'), calc):  # reset SoC
        exit(1)
    if not send_data(port, 0x1B000004, 0x00000002.to_bytes(4, 'little'), calc):  # hold core in reset
        exit(1)
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
    if not send_data(port, 0x1B000008, 0x00000002.to_bytes(4, 'little'), calc):  # allow core to run
        exit(1)
    print('Programming complete.')
else:
    print('Writing to non-standard address (not programming)')
    if not send_data(port, addr, file_data, calc, True):  # write RAM data
        exit(1)
