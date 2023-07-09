`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 20.06.2023 20:21:48
// Design Name: 
// Module Name: soc_video_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: VGA-based video controller, consisting of a Digilent VGA controller module and a framebuffer of configurable size.
//              Note: Image size changes require changes vga_digilent.vhd as well.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module soc_video_controller #(
        parameter FB_ADDR_WIDTH = 18,
        parameter FB_LATENCY = 1,
        parameter FB_MEM_SIZE = 1536000,
        parameter VGA_OFFSET = 0,
        parameter VGA_FIRST_LINE = 35,
        parameter VGA_LAST_LINE = 515
    ) (
        input main_clk,
        input vga_clk,
        input res,
        
        output vga_hsync,
        output vga_vsync,
        output [3:0] vga_r,
        output [3:0] vga_g,
        output [3:0] vga_b,
        
        SoC_MemBus.Slave fb_mem_bus
    );
    
    wire [7:0] data_out;
    wire [31:0] pxl_addr;
    
    soc_framebuffer #(
        .ADDR_WIDTH_A(FB_ADDR_WIDTH),
        .LATENCY_A(FB_LATENCY),
        .ADDR_WIDTH_B(32),
        .MEM_SIZE(FB_MEM_SIZE)
    ) vga_framebuffer (
        .main_clk(main_clk),
        .vga_clk(vga_clk),
        .res(res),
        .bus_a(fb_mem_bus),
        .word_addr_b(pxl_addr),
        .read_data_b(data_out)
    );
    
    soc_vga #(
        .FRAME_OFFSET(VGA_OFFSET),
        .FIRST_LINE(VGA_FIRST_LINE),
        .LAST_LINE(VGA_LAST_LINE)
    ) vga_controller (
        .clk(vga_clk),
        .res(1'b0), //resetting the VGA controller seems to be a bad idea, it causes the display to lose synchronisation
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .pixel_address(pxl_addr),
        .pixel_data(data_out)
    );
    
endmodule
