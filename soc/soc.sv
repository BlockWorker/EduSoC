`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 20.06.2023 13:02:01
// Design Name: 
// Module Name: soc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Central SoC component. Instantiation and connection module for all parts of the SoC.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "soc_defines.sv"


module soc(
        input ext_clk,
        input ext_resn,
        output [3:0] leds,
        output [2:0] led_rgb0,
        output [2:0] led_rgb1,
        input [3:0] buttons,
        input [3:0] switches,
        output vga_hsync,
        output vga_vsync,
        output [3:0] vga_r,
        output [3:0] vga_g,
        output [3:0] vga_b,
        input uart_rx,
        output uart_tx,
        
        output main_clk,
        output res,
        
        SoC_MemBus.Slave instr_bus,
        SoC_MemBus.Slave data_bus,
        
        SoC_InterruptBus.Generator int_bus
    );
    
    wire uart_clk;
    
    soc_clock_reset #(
        .UART_PLL_DIVIDER(`UART_CLK_DIVIDER_PLL),
        .UART_POST_DIVIDER(`UART_CLK_DIVIDER_POST)
    ) clk_rst_gen (
        .in_clk(ext_clk),
        .main_clk(main_clk),
        .uart_clk(uart_clk),
        .in_rst_n(ext_resn),
        .out_rst(res)
    );
    
    SoC_MemBus bus();
    
    soc_uart_bridge uart_bridge (
        .clk(main_clk),
        .uclk(uart_clk),
        .res(res),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .mem_bus(bus.Master)
    );
    
    soc_video_controller #(
        .FB_ADDR_WIDTH(`VIDEO_FB_ADDR_WIDTH),
        .FB_LATENCY(`VIDEO_FB_LATENCY),
        .FB_MEM_SIZE(`VIDEO_FB_MEM_SIZE)
    ) vid (
        .clk(main_clk),
        .res(res),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .fb_mem_bus(bus.Slave)
    );
    
endmodule
