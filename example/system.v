`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 
// Design Name: 
// Module Name: system
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example system top component using EduSoC with a simple RISC-V core
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module system (
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

  wire CPU_CLK;
  wire CPU_RES;
  wire INSTR_REQ;
  wire INSTR_VALID;
  wire [31:0] INSTR_ADDR;
  wire [31:0] INSTR_RDATA;
  wire CACHED_INSTR_REQ;
  wire CACHED_INSTR_VALID;
  wire [31:0] CACHED_INSTR_ADDR;
  wire [31:0] CACHED_INSTR_RDATA;
  wire DATA_REQ;
  wire DATA_VALID;
  wire DATA_WE;
  wire [3:0] DATA_BE;
  wire [31:0] DATA_ADDR;
  wire [31:0] DATA_WDATA;
  wire [31:0] DATA_RDATA;
  wire IRQ;
  wire [4:0] IRQ_ID;
  wire IRQ_ACK;
  wire [4:0] IRQ_ACK_ID;

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
      .CPU_CLK(CPU_CLK),
      .CPU_RES(CPU_RES),
      .INSTR_REQ(INSTR_REQ),
      .INSTR_VALID(INSTR_VALID),
      .INSTR_ADDR(INSTR_ADDR),
      .INSTR_RDATA(INSTR_RDATA),
      .DATA_REQ(DATA_REQ),
      .DATA_VALID(DATA_VALID),
      .DATA_WE(DATA_WE),
      .DATA_BE(DATA_BE),
      .DATA_ADDR(DATA_ADDR),
      .DATA_WDATA(DATA_WDATA),
      .DATA_RDATA(DATA_RDATA),
      .IRQ(IRQ),
      .IRQ_ID(IRQ_ID),
      .IRQ_ACK(IRQ_ACK),
      .IRQ_ACK_ID(IRQ_ACK_ID)
  );

  proc proc (
      .CLK(CPU_CLK),
      .RES(CPU_RES),
      .INSTR_REQ(CACHED_INSTR_REQ),
      .INSTR_VALID(CACHED_INSTR_VALID),
      .INSTR_ADR(CACHED_INSTR_ADDR),
      .INSTR_READ(CACHED_INSTR_RDATA),
      .DATA_REQ(DATA_REQ),
      .DATA_VALID(DATA_VALID),
      .DATA_WRITE_ENABLE(DATA_WE),
      .DATA_BE(DATA_BE),
      .DATA_ADR(DATA_ADDR),
      .DATA_WRITE(DATA_WDATA),
      .DATA_READ(DATA_RDATA),
      .IRQ(IRQ),
      .IRQ_ID(IRQ_ID),
      .IRQ_ACK(IRQ_ACK),
      .IRQ_ACK_ID(IRQ_ACK_ID)
  );

  cache #(
      .INDEX_BITS(6)
  ) cache (
      .clk(CPU_CLK),
      .res(CPU_RES),
      .cached_instr_req(CACHED_INSTR_REQ),
      .cached_instr_adr(CACHED_INSTR_ADDR),
      .cached_instr_valid(CACHED_INSTR_VALID),
      .cached_instr_read(CACHED_INSTR_RDATA),
      .instr_req(INSTR_REQ),
      .instr_adr(INSTR_ADDR),
      .instr_valid(INSTR_VALID),
      .instr_read(INSTR_RDATA)
  );

endmodule
