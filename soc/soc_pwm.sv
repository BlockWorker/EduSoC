`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.06.2023 12:10:22
// Design Name: 
// Module Name: soc_pwm
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Pulse width modulated signal generator for the SoC. Supports up to 16 independent modules/outputs.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


import registers::*;

typedef enum logic [3:0] {
  CONTROL = 0,
  VALUE = 1,
  NEXT_VALUE = 2
} pwm_conf_t;

module soc_pwm #(
    parameter BUS_LATENCY = 1,
    parameter MODULE_COUNT = 1,  //how many PWM modules are created (1 pin each)
    parameter TIMER_COUNT = 1  //how many independent timers are available to drive the PWM modules
) (
    input clk,
    input res,

    input [31:0] timer_counts[TIMER_COUNT-1:0],
    output [MODULE_COUNT-1:0] pwm_outputs,

    SoC_MemBus.Slave mem_bus
);

  initial
    assert (MODULE_COUNT <= 16 && TIMER_COUNT <= 16)
    else $error("PWM controller only supports up to 16 modules and timers.");

  wire [31:0] addr;
  wire [3:0] register_index = addr[11:8];  //index of selected PWM module
  pwm_conf_t register_addr;  //local register address within selected module
  reg_access_t register_type;  //register access type
  reg [31:0] register_value;
  wire [31:0] register_write;
  wire write_enabled;

  reg [31:0] controls[MODULE_COUNT-1:0];
  reg [31:0] values[MODULE_COUNT-1:0];
  reg [31:0] next_values[MODULE_COUNT-1:0];
  wire enables[MODULE_COUNT-1:0];
  wire [3:0] timer_indices[MODULE_COUNT-1:0];

  assign register_type = reg_access_t'(addr[3:2]);
  assign register_addr = pwm_conf_t'(addr[7:4]);

  //memory bus controller
  soc_peripheral_controller #(
      .LATENCY(BUS_LATENCY)
  ) per_ctl (
      .clk(clk),
      .res(res),
      .bus(mem_bus),
      .data_out(register_value),
      .unchanged_value(register_value),
      .addr_out(addr),
      .write_data(register_write),
      .we(write_enabled)
  );

  //PWM generation
  generate
    genvar i;

    for (i = 0; i < MODULE_COUNT; i++) begin
      assign enables[i] = controls[i][8];
      assign timer_indices[i] = controls[i][3:0];

      assign pwm_outputs[i] = enables[i] && (timer_counts[timer_indices[i]] < values[i]);
    end
  endgenerate

  //register read value assignment
  always @(*) begin
    register_value = 32'b0;

    if (register_type == MAIN && register_index < MODULE_COUNT) begin
      case (register_addr)
        CONTROL: register_value = controls[register_index];
        VALUE: register_value = values[register_index];
        NEXT_VALUE: register_value = next_values[register_index];
      endcase
    end
  end

  //register writing and value propagation
  always @(posedge clk) begin
    if (res) begin
      for (int i = 0; i < MODULE_COUNT; i++) begin
        controls[i] <= 32'b0;
        values[i] <= 32'b0;
        next_values[i] <= 32'b0;
      end
    end else begin
      if (write_enabled && register_index < MODULE_COUNT) begin
        case (register_addr)
          CONTROL: begin  //write to control register, ignore reserved bits
            controls[register_index] <=
                writeval(controls[register_index], register_write, register_type) & 32'h10F;
          end
          NEXT_VALUE: begin  //write to next value register
            next_values[register_index] <=
                writeval(next_values[register_index], register_write, register_type);
          end
        endcase
      end

      for (int i = 0; i < MODULE_COUNT; i++) begin
        if (timer_counts[timer_indices[i]] == 32'b0) begin  //timer reached 0: load next value
          values[i] <= next_values[i];
        end
      end
    end
  end

endmodule
