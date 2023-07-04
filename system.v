`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 22.06.2023 13:55:05
// Design Name: 
// Module Name: system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Basic system top component using EduSoC
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module system(
        input BOARD_CLK,
        input BOARD_RESN,
        output [3:0] BOARD_LED,
        output [2:0] BOARD_LED_RGB0,
        output [2:0] BOARD_LED_RGB1,
        input [3:0] BOARD_BUTTON,
        input [3:0] BOARD_SWITCH,
        output BOARD_VGA_HSYNC,
        output BOARD_VGA_VSYNC,
        output [3:0] BOARD_VGA_R,
        output [3:0] BOARD_VGA_G,
        output [3:0] BOARD_VGA_B,
        input BOARD_UART_RX,
        output BOARD_UART_TX
    );
    
    edusoc_basic soc (
        .BOARD_CLK(BOARD_CLK),
        .BOARD_RESN(BOARD_RESN),
        .BOARD_LED(BOARD_LED),
        .BOARD_LED_RGB0(BOARD_LED_RGB0),
        .BOARD_LED_RGB1(BOARD_LED_RGB1),
        .BOARD_BUTTON(BOARD_BUTTON),
        .BOARD_SWITCH(BOARD_SWITCH),
        .BOARD_VGA_HSYNC(BOARD_VGA_HSYNC),
        .BOARD_VGA_VSYNC(BOARD_VGA_VSYNC),
        .BOARD_VGA_R(BOARD_VGA_R),
        .BOARD_VGA_G(BOARD_VGA_G),
        .BOARD_VGA_B(BOARD_VGA_B),
        .BOARD_UART_RX(BOARD_UART_RX),
        .BOARD_UART_TX(BOARD_UART_TX),
        .CPU_CLK(),
        .CPU_RES(),
        .INSTR_REQ(1'b0),
        .INSTR_VALID(),
        .INSTR_ADDR(32'b0),
        .INSTR_RDATA(),
        .DATA_REQ(1'b0),
        .DATA_VALID(),
        .DATA_WE(1'b0),
        .DATA_BE(4'b0),
        .DATA_ADDR(32'b0),
        .DATA_WDATA(32'b0),
        .DATA_RDATA(),
        .IRQ(),
        .IRQ_ID(),
        .IRQ_ACK(1'b0),
        .IRQ_ACK_ID(5'b0)
    );
    
endmodule
