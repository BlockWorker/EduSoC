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
        parameter FB_MEM_SIZE = 1536000
    ) (
        input clk,
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
        .clk(clk),
        .res(res),
        .bus_a(fb_mem_bus),
        .word_addr_b(pxl_addr),
        .read_data_b(data_out)
    );
    
    vga_digilent vga_controller(            
        .pxl_clk(clk),
        .PXL_ADR_O(pxl_addr),
        .PIXEL_I(data_out),
        .VGA_HS_O(vga_hsync),
        .VGA_VS_O(vga_vsync),
        .VGA_R(vga_r),
        .VGA_G(vga_g),
        .VGA_B(vga_b)
    );
    
endmodule
