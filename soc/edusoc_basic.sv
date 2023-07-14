`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 25.06.2023 17:38:00
// Design Name: 
// Module Name: edusoc_basic
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: System wrapper for a basic EduSoC configuration, compatible with Verilog. Use this to include EduSoC in an Arty-7 system design.
//              Internally, just a wrapper for the central 'soc' component, fanning out all interface buses to simple logic signals.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

import globalconf::*;

module edusoc_basic (
    /* BOARD SIGNALS */
    input BOARD_CLK,
    input BOARD_RESN,

    output [3:0] BOARD_LED,
    output [2:0] BOARD_LED_RGB0,
    output [2:0] BOARD_LED_RGB1,

    input [3:0] BOARD_BUTTON,
    input [3:0] BOARD_SWITCH,

    output       BOARD_VGA_HSYNC,
    output       BOARD_VGA_VSYNC,
    output [3:0] BOARD_VGA_R,
    output [3:0] BOARD_VGA_G,
    output [3:0] BOARD_VGA_B,
    input        BOARD_UART_RX,
    output       BOARD_UART_TX,

    /* CORE SIGNALS */
    output CPU_CLK,
    output CPU_RES,

    // Instruction memory interface
    input         INSTR_REQ,
    output        INSTR_VALID,
    input  [31:0] INSTR_ADDR,
    output [31:0] INSTR_RDATA,

    // Data memory interface
    input         DATA_REQ,
    output        DATA_VALID,
    input         DATA_WE,
    input  [ 3:0] DATA_BE,
    input  [31:0] DATA_ADDR,
    input  [31:0] DATA_WDATA,
    output [31:0] DATA_RDATA,

    // Interrupt outputs
    output       IRQ,
    output [4:0] IRQ_ID,
    // Interrupt inputs
    input        IRQ_ACK,
    input  [4:0] IRQ_ACK_ID
);

  //bus instances
  SoC_MemBus instr_bus (), data_bus ();
  SoC_InterruptBus int_bus ();

  //GPIO and PWM wires
  wire [(32*GPIO_PORT_COUNT)-1:0] gpio_in;
  wire [(32*GPIO_PORT_COUNT)-1:0] gpio_out;
  wire [PWM_MODULE_COUNT-1:0] pwm;

  //actual SoC component
  edusoc soc (
      .ext_clk(BOARD_CLK),
      .ext_resn(BOARD_RESN),
      .vga_hsync(BOARD_VGA_HSYNC),
      .vga_vsync(BOARD_VGA_VSYNC),
      .vga_r(BOARD_VGA_R),
      .vga_g(BOARD_VGA_G),
      .vga_b(BOARD_VGA_B),
      .uart_rx(BOARD_UART_RX),
      .uart_tx(BOARD_UART_TX),
      .gpio_in(gpio_in),
      .gpio_out(gpio_out),
      .gpio_drive(),
      .pwm(pwm),
      .core_clk(CPU_CLK),
      .core_res(CPU_RES),
      .control_flags(),
      .instr_bus(instr_bus.Slave),
      .data_bus(data_bus.Slave),
      .core_int_triggers(16'b0),
      .int_bus(int_bus.Generator)
  );

  //GPIO and PWM connections
  assign BOARD_LED = gpio_out[3:0];
  assign BOARD_LED_RGB0 = pwm[2:0] | gpio_out[10:8];
  assign BOARD_LED_RGB1 = pwm[5:3] | gpio_out[14:12];
  assign gpio_in[19:16] = BOARD_BUTTON;
  assign gpio_in[23:20] = BOARD_SWITCH;
  assign gpio_in[15:0] = 16'b0;
  assign gpio_in[31:24] = 8'b0;

  //instruction bus fanout - read-only bus, so write-related signals tied to zero
  assign instr_bus.addr = INSTR_ADDR;
  assign instr_bus.write_data = 32'b0;
  assign instr_bus.write_en = 0;
  assign instr_bus.byte_en = 4'b0;
  assign instr_bus.req = INSTR_REQ;
  assign INSTR_RDATA = instr_bus.read_data;
  assign INSTR_VALID = instr_bus.valid;

  //data bus fanout
  assign data_bus.addr = DATA_ADDR;
  assign data_bus.write_data = DATA_WDATA;
  assign data_bus.write_en = DATA_WE;
  assign data_bus.byte_en = DATA_BE;
  assign data_bus.req = DATA_REQ;
  assign DATA_RDATA = data_bus.read_data;
  assign DATA_VALID = data_bus.valid;

  //interrupt bus fanout
  assign IRQ = int_bus.irq;
  assign IRQ_ID = int_bus.irq_id;
  assign int_bus.irq_ack = IRQ_ACK;
  assign int_bus.irq_ack_id = IRQ_ACK_ID;

endmodule
