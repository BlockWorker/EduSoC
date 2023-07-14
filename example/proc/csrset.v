`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: csrset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - Control and Status Registers. Units of RDTIME are defined as milliseconds.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`define CLK_MAIN_DIVIDER 32

module csrset #(
    parameter CORE_ID = 32'd0
) (
    input CLK,
    input RES,
    input INSTR_DONE,
    input [11:0] ADR,
    output reg [31:0] OUT
);

  localparam CYCLES_PER_MS = 800000 / `CLK_MAIN_DIVIDER;  //CPU cycles per millisecond

  reg [63:0] RDCYCLE;
  reg [63:0] RDTIME;
  reg [63:0] RDINSTRET;

  reg [31:0] time_cycle_count;

  always @(posedge CLK) begin
    if (RES) begin
      time_cycle_count <= 32'd0;
      RDCYCLE <= 64'd0;
      RDTIME <= 64'd0;
      RDINSTRET <= 64'd0;
    end else begin
      RDCYCLE <= RDCYCLE + 64'd1;
      if (time_cycle_count == (CYCLES_PER_MS - 1)) begin
        time_cycle_count <= 32'd0;
        RDTIME <= RDTIME + 64'd1;
      end else begin
        time_cycle_count <= time_cycle_count + 32'd1;
      end
      if (INSTR_DONE) RDINSTRET <= RDINSTRET + 64'd1;
    end
  end

  always @(*) begin
    case (ADR)
      12'hC00: OUT = RDCYCLE[31:0];
      12'hC01: OUT = RDTIME[31:0];
      12'hC02: OUT = RDINSTRET[31:0];
      12'hC80: OUT = RDCYCLE[63:32];
      12'hC81: OUT = RDTIME[63:32];
      12'hC82: OUT = RDINSTRET[63:32];
      12'hF14: OUT = CORE_ID;
      default: OUT = 32'd0;
    endcase
  end

endmodule
