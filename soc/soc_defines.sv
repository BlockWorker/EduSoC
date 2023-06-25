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

//UART clock - by default, configured for 500 kBaud -> 8 MHz clock
`define UART_CLK_DIVIDER_PLL 100 //divider down from 800Mhz, 1-128
`define UART_CLK_DIVIDER_POST 1 //post-divider after above division, either 1 or a multiple of 2

//Video framebuffer interface options
`define VIDEO_FB_ADDR_WIDTH 18
`define VIDEO_FB_LATENCY 1

//Video framebuffer size - see a few options below. Changes to display size / bit width also need changes in 'vga_digilent.vhd'.
//640px*480px*6bit/px=1843200 (4:3)
//640px*300px*8bit/px=1536000 (32:15)
//640px*360px*8bit/px=1843200 (16:9)
`define VIDEO_FB_MEM_SIZE 1843200

`endif //include guard