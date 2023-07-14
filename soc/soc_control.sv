`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.06.2023 12:10:22
// Design Name: 
// Module Name: soc_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: SoC controller peripheral. Allows resets to be forced, the core to be halted, and handles interrupt control.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


import registers::*;
import globalconf::*;

typedef enum logic [7:0] {
  REG_SOCCTL_CONTROL = 0,
  REG_SOCCTL_INT_EN = 1,
  REG_SOCCTL_INT_FLAGS = 2,
  REG_SOCCTL_CLK_FREQ = 3
} socctl_t;

module soc_control #(
    parameter BUS_LATENCY = 1
) (
    input clk,
    input raw_res,

    output core_halt,
    output core_res,
    output soc_res,
    output [15:0] control_flags,

    input [31:0] int_triggers,

    SoC_MemBus.Slave mem_bus,
    SoC_InterruptBus.Generator int_bus
);

  reg [31:0] int_clears;
  reg [31:0] int_enables;
  wire [31:0] asserted_ints;
  reg [31:0] control_register;
  wire [31:0] clock_frequency = 800_000_000 / CLK_MAIN_DIVIDER;

  wire [31:0] addr;
  socctl_t register_addr;  //local register address
  reg_access_t register_type;  //register access type
  reg [31:0] register_value;
  wire [31:0] register_write;

  assign register_addr = socctl_t'(addr[11:4]);
  assign register_type = reg_access_t'(addr[3:2]);
  wire write_enabled;

  //SoC interrupt controller
  soc_interrupt_controller int_ctl (
      .clk(clk),
      .res(soc_res),
      .int_bus(int_bus),
      .enabled_int(control_register[3] ? int_enables : 32'b0), //mask int enables with global int enable
      .int_clears(int_clears),
      .int_triggers(int_triggers),
      .asserted_ints(asserted_ints)
  );

  //memory bus controller
  soc_peripheral_controller #(
      .LATENCY(BUS_LATENCY)
  ) per_ctl (
      .clk(clk),
      .res(soc_res),
      .bus(mem_bus),
      .data_out(register_value),
      .unchanged_value(register_value),
      .addr_out(addr),
      .write_data(register_write),
      .we(write_enabled)
  );

  //control register fanout
  assign core_halt = control_register[0];
  assign core_res = raw_res || control_register[1];
  assign soc_res = raw_res || control_register[2];
  assign control_flags = control_register[31:16];

  initial control_register <= 32'b0;

  //register read value assignment
  always @(*) begin
    register_value = 32'b0;

    if (register_type == MAIN) begin
      case (register_addr)
        REG_SOCCTL_CONTROL: register_value = control_register;
        REG_SOCCTL_INT_EN: register_value = int_enables;
        REG_SOCCTL_INT_FLAGS: register_value = asserted_ints;
        REG_SOCCTL_CLK_FREQ: register_value = clock_frequency;
        default:  /* Do nothing in case of an invalid address. */;
      endcase
    end
  end

  //register writing
  always @(posedge clk) begin
    int_clears <= 32'b0; //reset clears, if any set from previous clock cycle (since clear should have happened now)

    if (soc_res) begin
      int_enables <= 32'b0;
      control_register[15:0] <= 16'h8;  //interrupts globally enabled at reset
    end else if (write_enabled) begin
      case (register_addr)
        REG_SOCCTL_CONTROL: begin  //write to control register, ignore reserved bits
          control_register <= writeval(control_register, register_write, register_type) &
              32'hFFFF000F;
        end
        REG_SOCCTL_INT_EN: begin  //write to interrupt enable register
          int_enables <= writeval(int_enables, register_write, register_type);
        end
        REG_SOCCTL_INT_FLAGS: begin  //write to interrupt flags register: can only be cleared
          int_clears <= clearonly(int_clears, register_write, register_type);
        end
        default:  /* Do nothing in case of an invalid address. */;
      endcase
    end
  end

endmodule
