mret # Interrupt 0
mret # Interrupt 1
mret # Interrupt 2
mret # Interrupt 3
mret # Interrupt 4
mret # Interrupt 5
mret # Interrupt 6
mret # Interrupt 7
mret # Interrupt 8
mret # Interrupt 9
mret # Interrupt 10
mret # Interrupt 11
mret # Interrupt 12
mret # Interrupt 13
mret # Interrupt 14
j irq # Interrupt 15
mret # Interrupt 16
mret # Interrupt 17
mret # Interrupt 18
mret # Interrupt 19
mret # Interrupt 20
mret # Interrupt 21
mret # Interrupt 22
mret # Interrupt 23
mret # Interrupt 24
mret # Interrupt 25
mret # Interrupt 26
mret # Interrupt 27
mret # Interrupt 28
mret # Interrupt 29
mret # Interrupt 30
mret # Interrupt 31

lui x1, 0x1B000 # SoC control base address
lui x2, 0x00008 # Bit 15 for interrupt 15
sw x2, 0x014(x1) # Enable interrupt 15 (GPIO)
loop:
j loop # wait for interrupts

irq:
lui x1, 0x1B001 # GPIO base address
lw x2, 0x000(x1) # read GPIO port
srli x2, x2, 16 # shift button/switch states to last byte
srli x3, x2, 4 # shift switch states to last 4 bits
xor x2, x2, x3 # calculate XOR between switches and buttons
andi x2, x2, 0x00F # remove all except for lowest 4 bits (= LEDs)
sw x2, 0x000(x1) # write to GPIO port
mret
