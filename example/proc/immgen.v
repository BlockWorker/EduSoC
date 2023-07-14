//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: immgen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - immediate value generator
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module immgen (
    input [31:0] INSTR,
    input [2:0] MODE,
    output reg [31:0] IMM
);

  always @(*) begin
    case (MODE)
      `IMM_ZERO: IMM = 32'd0;
      `IMM_I: IMM = {{20{INSTR[31]}}, INSTR[31:20]};
      `IMM_S: IMM = {{20{INSTR[31]}}, INSTR[31:25], INSTR[11:7]};
      `IMM_B: IMM = {{19{INSTR[31]}}, INSTR[7], INSTR[31:25], INSTR[11:8], 1'd0};
      `IMM_U: IMM = {INSTR[31:12], 12'd0};
      `IMM_J: IMM = {{12{INSTR[31]}}, INSTR[19:12], INSTR[20], INSTR[30:25], INSTR[24:21], 1'd0};
      `IMM_CONST_4: IMM = 32'd4;
      default: IMM = 32'd0;
    endcase
  end

endmodule
