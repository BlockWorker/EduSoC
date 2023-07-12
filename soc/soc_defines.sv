//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 22.06.2023 16:19:06
// Design Name: 
// Module Name: soc_defines
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Various constant definitions for EduSoC.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`ifndef SOC_DEFINES_HEADER //include guard
`define SOC_DEFINES_HEADER


`include "soc_registers.sv"



//**************************** MEMORY/BUS ****************************
//Memory sizes - specify the address width in bits, which is log2(memory size in bytes)
`define MEM_BOOTROM_ADDR_WIDTH      13 //8 KB Boot ROM
`define MEM_RAM_ADDR_WIDTH          16 //64 KB main RAM
`define MEM_FRAMEBUFFER_ADDR_WIDTH  18 //up to 256 KB framebuffer - actual size set below

//Memory initialization files - either "none" or filename of .mem file
`ifdef XILINX_SIMULATOR
`define MEM_BOOTROM_INIT    "sim_bootrom.mem"
`define MEM_RAM_INIT        "sim_ram.mem"
`else
`define MEM_BOOTROM_INIT    "bootloader.mem"
`define MEM_RAM_INIT        "none"
`endif

//Memory latencies in clock cycles (+1 inherent latency)
`define MEM_BOOTROM_LATENCY     1
`define MEM_RAM_LATENCY         7
`define MEM_PERIPHERAL_LATENCY  0
`define MEM_FRAMEBUFFER_LATENCY 3

//Address space definitions
`define ADDR_SLAVE_COUNT        7
`define ADDR_BOOTROM_START      'h1A000000
`define ADDR_BOOTROM_END        'h1A001FFF
`define ADDR_SOCCON_START       'h1B000000
`define ADDR_SOCCON_END         'h1B000FFF
`define ADDR_GPIO_START         'h1B001000
`define ADDR_GPIO_END           'h1B001FFF
`define ADDR_TIMERS_START       'h1B002000
`define ADDR_TIMERS_END         'h1B002FFF
`define ADDR_PWM_START          'h1B003000
`define ADDR_PWM_END            'h1B003FFF
`define ADDR_RAM_START          'h1C000000
`define ADDR_RAM_END            'h1C00FFFF
`define ADDR_FRAMEBUFFER_START  'h1D000000
`define ADDR_FRAMEBUFFER_END    'h1D03FFFF



//**************************** CLOCK ****************************
//Main clock - by default, configured for 25 MHz
`define CLK_MAIN_DIVIDER        32 //divider down from 800Mhz, 1-128
//VGA clock - by default, configured for 25 MHz (requirement for 640x480 display)
`define CLK_VGA_DIVIDER         32 //divider down from 800Mhz, 1-128
//UART clock - by default, configured for 500 kBaud -> 8 MHz clock
`define CLK_UART_DIVIDER_PLL    100 //divider down from 800Mhz, 1-128
`define CLK_UART_DIVIDER_POST   1 //post-divider after PLL division, either 1 or a multiple of 2



//**************************** VIDEO ****************************
//Video framebuffer size in bits - see a few options below.
//640px*300px*8bit/px=1536000 (32:15)
//640px*360px*8bit/px=1843200 (16:9)
`define VIDEO_FB_MEM_SIZE 1843200

//VGA output properties
`define VIDEO_VGA_OFFSET 60 //vertical offset of image in 640x480 frame (640x480: 0, 640x360: 60, 640x300: 90)
`define VIDEO_VGA_FIRST_LINE 95 //first line index that is active (640x480: 35, 640x360: 95, 640x300: 125)
`define VIDEO_VGA_LAST_LINE 455 //first line index that is active (640x480: 515, 640x360: 455, 640x300: 425)



//**************************** PERIPHERALS ****************************
//GPIO port count - each port provides the hardware for 32 GPIO pins, maximum 16 ports
`define GPIO_PORT_COUNT 1

//Timer count - how many independent timer modules there are, maximum 16 modules
`define TIMER_COUNT 2

//PWM module count - each module can drive one GPIO pin in PWM mode, maximum 16 modules
`define PWM_MODULE_COUNT 6



`endif //include guard
