# EduSoC bootloader for UART programming

# Initialize SoC for Arty S7 board (edusoc-basic configuration)
lui x1, 0x1B001			# gpio base address
li x2, 0x0000770F		# gpio directions required (LEDs output, others input)
sw x2, 0x020(x1)		# write gpio directions
lui x2, 0x00FF0			# change notification pins (switches+buttons enable, others disable)
sw x2, 0x030(x1)		# enable rising edge notifications
sw x2, 0x040(x1)		# enable falling edge notifications

# Reset: Check for control flag indicating successful UART programming
lui x1, 0x1B000			# controller base address
lw x2, 0(x1)			# read control register
lui x3, 0x00010			# expected control flag (flag 0)
and x2, x2, x3			# only care about flag 0
bne x2, x3, idle		# if control flags not as expected: not programmed yet, go to idle loop
li x1, 0x1C000080	  	# RAM code address
jr x1					# control flags set as expected: programmed -> jump to RAM code

# RAM not programmed: Show processor working with some idle LED flashing
idle:
lui x1, 0x1B002
lui x2, 0x10000
sw x2, 0x020(x1)
addi x2, x0, 1
sw x2, 0(x1)
lui x3, 0x1B001
idle_loop:
lw x2, 0x010(x1)
srli x2, x2, 24
andi x2, x2, 0xF
sw x2, 0(x3)
j idle_loop