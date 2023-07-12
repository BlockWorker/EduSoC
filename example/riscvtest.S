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
j isr # Interrupt 11
mret # Interrupt 12
mret # Interrupt 13
mret # Interrupt 14
mret # Interrupt 15
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

j program_start

isr:
addi x1, x0, 1                  # Set interrupt flag
mret                            # Return from ISR

error:
jal x0, error

program_start:
addi x31, x0, 1  # Test 1: add commands
addi x1, x0, 10
addi x2, x0, 20
add x3, x1, x2

addi x30, x0, 30
bne x3, x30, error

addi x31, x0, 2  # Test 2: subtract
addi x1, x0, 20
addi x2, x0, 5
sub x3, x1, x2

addi x30, x0, 15
bne x30, x3, error

addi x31, x0, 3  # Test 3: upper immediate loads (no good way to check result)
auipc x1, 1
lui x2, 1

addi x31, x0, 4  # Test 4: binary operators
addi x1, x0, 0b01010101
addi x2, x0, 0b00001111
andi x3, x1, 0b11110000
ori x4, x1, 0b11110000
xori x5, x1, 0b11110000
and x6, x1, x2
or x7, x1, x2
xor x8, x1, x2

addi x30, x0, 0b01010000
bne x30, x3, error
addi x30, x0, 0b11110101
bne x30, x4, error
addi x30, x0, 0b10100101
bne x30, x5, error
addi x30, x0, 0b00000101
bne x30, x6, error
addi x30, x0, 0b01011111
bne x30, x7, error
addi x30, x0, 0b01011010
bne x30, x8, error

addi x31, x0, 5  # Test 5: shifts
addi x1, x0, 0xff8
addi x2, x0, 4
slli x3, x1, 1
srli x4, x1, 1
srai x5, x1, 1
sll x6, x1, x2
srl x7, x1, x2
sra x8, x1, x2

addi x30, x0, 0xff0
bne x30, x3, error
lui x30, 0x80000
addi x30, x30, 0xffc
bne x30, x4, error
addi x30, x0, 0xffc
bne x30, x5, error
addi x30, x0, 0xf80
bne x30, x6, error
lui x30, 0x10000
addi x30, x30, 0xfff
bne x30, x7, error
addi x30, x0, 0xfff
bne x30, x8, error

addi x31, x0, 6  # Test 6: SLT
addi x1, x0, 2
addi x2, x0, 2
addi x3, x0, 0xfff
slti x4, x1, 1
slti x5, x1, 2
slti x6, x1, 3
slti x7, x3, 3
sltiu x8, x1, 1
sltiu x9, x1, 2
sltiu x10, x1, 3
sltiu x11, x3, 3
slt x12, x1, x0
slt x13, x1, x2
slt x14, x1, x3
sltu x15, x1, x0
sltu x16, x1, x2
sltu x17, x1, x3

addi x30, x0, 0
bne x30, x4, error
bne x30, x5, error
bne x30, x8, error
bne x30, x9, error
bne x30, x11, error
bne x30, x12, error
bne x30, x13, error
bne x30, x14, error
bne x30, x15, error
bne x30, x16, error
addi x30, x0, 1
bne x30, x6, error
bne x30, x7, error
bne x30, x10, error
bne x30, x17, error

addi x31, x0, 7  # Test 7: Load/Store
addi x1, x0, 42
addi x2, x0, 24
lui x3, 0x1c008
addi x3, x3, 20
sw x1, 0(x3)
sw x2, 4(x3)
addi x4, x0, 0
addi x5, x0, 0
lw x4, 0(x3)
lw x5, 4(x3)

addi x30, x0, 42
bne x30, x4, error
addi x30, x0, 24
bne x30, x5, error

addi x31, x0, 8  # Test 8: Interrupt
lui x1, 0x1b000                 # controller base address
li x2, 0x800      				# set bit 11
sw x2, 0x014(x1)                # write to INT_EN_SET

lui x1, 0x1b002                 # timer base address
addi x2, x0, 100                # Timer count length: 100 cycles
sw x2, 0x020(x1)               	# write to period register
addi x2, x0, 0x7                # timer control bits (enable interrupt, oneshot, enable)
sw x2, 0(x1)                    # write to control register

addi x1, x0, 0                  # Clear interrupt flag, will be set by ISR
addi x2, x0, 50                 # Initialize "timeout error" counter

wait:
addi x2, x2, -1                 # Decrement counter
blt x2, x0, error               # Go to error if counter goes below zero
beq x1, x0, wait                # While interrupt flag is zero, stay in loop

addi x31, x0, 9  # Test 9: Multiply
addi x1, x0, 15
addi x2, x0, 76
mul x3, x1, x2
addi x30, x0, 1140
bne x30, x3, error

addi x31, x0, 10  # Test 10: Irregular memory access
lui x1, 0x1C008
addi x1, x1, 0xC30
lui x2, 0xF4F3F
addi x2, x2, 0x2F1
sw x2, 0(x1)
lui x2, 0xF8F7F
addi x2, x2, 0x6F5
sw x2, 4(x1)

lui x30, 0xF4F3F
addi x30, x30, 0x2F1
lw x29, 0(x1)
bne x30, x29, error
lui x30, 0xF5F4F
addi x30, x30, 0x3F2
lw x29, 1(x1)
bne x30, x29, error
lui x30, 0xF6F5F
addi x30, x30, 0x4F3
lw x29, 2(x1)
bne x30, x29, error
lui x30, 0xF7F6F
addi x30, x30, 0x5F4
lw x29, 3(x1)
bne x30, x29, error

lui x30, 0xFFFFF
addi x30, x30, 0x2F1
lh x29, 0(x1)
bne x30, x29, error
lui x30, 0xFFFFF
addi x30, x30, 0x3F2
lh x29, 1(x1)
bne x30, x29, error
lui x30, 0xFFFFF
addi x30, x30, 0x4F3
lh x29, 2(x1)
bne x30, x29, error
lui x30, 0xFFFFF
addi x30, x30, 0x5F4
lh x29, 3(x1)
bne x30, x29, error

lui x30, 0x0000F
addi x30, x30, 0x2F1
lhu x29, 0(x1)
bne x30, x29, error
lui x30, 0x0000F
addi x30, x30, 0x3F2
lhu x29, 1(x1)
bne x30, x29, error
lui x30, 0x0000F
addi x30, x30, 0x4F3
lhu x29, 2(x1)
bne x30, x29, error
lui x30, 0x0000F
addi x30, x30, 0x5F4
lhu x29, 3(x1)
bne x30, x29, error

addi x30, x0, 0xFF1
lb x29, 0(x1)
bne x30, x29, error
addi x30, x0, 0xFF2
lb x29, 1(x1)
bne x30, x29, error
addi x30, x0, 0xFF3
lb x29, 2(x1)
bne x30, x29, error
addi x30, x0, 0xFF4
lb x29, 3(x1)
bne x30, x29, error

addi x30, x0, 0x0F1
lbu x29, 0(x1)
bne x30, x29, error
addi x30, x0, 0x0F2
lbu x29, 1(x1)
bne x30, x29, error
addi x30, x0, 0x0F3
lbu x29, 2(x1)
bne x30, x29, error
addi x30, x0, 0x0F4
lbu x29, 3(x1)
bne x30, x29, error

lui x2, 0x04030
addi x2, x2, 0x201
sw x2, 1(x1)
lui x30, 0x03020
addi x30, x30, 0x1f1
lw x29, 0(x1)
bne x30, x29, error
lui x30, 0xf8f7f
addi x30, x30, 0x604
lw x29, 4(x1)
bne x30, x29, error
lui x2, 0x14131
addi x2, x2, 0x211
sw x2, 2(x1)
lui x30, 0x12110
addi x30, x30, 0x1f1
lw x29, 0(x1)
bne x30, x29, error
lui x30, 0xf8f71
addi x30, x30, 0x413
lw x29, 4(x1)
bne x30, x29, error
lui x2, 0x24232
addi x2, x2, 0x221
sw x2, 3(x1)
lui x30, 0x21110
addi x30, x30, 0x1f1
lw x29, 0(x1)
bne x30, x29, error
lui x28, 0xf8242
addi x28, x28, 0x322
lw x29, 4(x1)
bne x28, x29, error

lui x2, 0xffff3
addi x2, x2, 0x231
sh x2, 0(x1)
lui x30, 0x21113
addi x30, x30, 0x231
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
lui x2, 0xffff4
addi x2, x2, 0x241
sh x2, 1(x1)
lui x30, 0x21424
addi x30, x30, 0x131
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
lui x2, 0xffff5
addi x2, x2, 0x251
sh x2, 2(x1)
lui x30, 0x52514
addi x30, x30, 0x131
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
lui x2, 0xffff6
addi x2, x2, 0x261
sh x2, 3(x1)
lui x30, 0x61514
addi x30, x30, 0x131
lw x29, 0(x1)
bne x30, x29, error
lui x28, 0xf8242
addi x28, x28, 0x362
lw x29, 4(x1)
bne x28, x29, error

addi x2, x0, 0xf71
sb x2, 0(x1)
lui x30, 0x61514
addi x30, x30, 0x171
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
addi x2, x0, 0xf81
sb x2, 1(x1)
lui x30, 0x61518
addi x30, x30, 0x171
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
addi x2, x0, 0xf91
sb x2, 2(x1)
lui x30, 0x61918
addi x30, x30, 0x171
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error
addi x2, x0, 0xfa1
sb x2, 3(x1)
lui x30, 0xa1918
addi x30, x30, 0x171
lw x29, 0(x1)
bne x30, x29, error
lw x29, 4(x1)
bne x28, x29, error

end:
jal x0, end
