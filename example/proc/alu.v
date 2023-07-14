//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - ALU
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module alu (
    input [6:0] S,
    input [31:0] A,
    input [31:0] B,
    output reg CMP,
    output reg [31:0] Q,
    output reg [31:0] MUL_OUT
);
  always @(S, A, B) begin
    Q = 32'd0;
    CMP = 1'b0;
    MUL_OUT = 32'd0;
    casez (S)
      `ALU_SUB:  Q = A - B;
      `ALU_MUL:  MUL_OUT = A * B;
      `ALU_ADD:  Q = A + B;
      `ALU_AND:  Q = A & B;
      `ALU_OR:   Q = A | B;
      `ALU_XOR:  Q = A ^ B;
      `ALU_SLL:  Q = A << B[4:0];
      `ALU_SRA:  Q = $signed(A) >>> B[4:0];
      `ALU_SRL:  Q = A >> B[4:0];
      `ALU_SLT:  Q = $signed(A) < $signed(B);
      `ALU_SLTU: Q = A < B;
      `ALU_EQ:   CMP = A == B;
      `ALU_NE:   CMP = A != B;
      `ALU_LT:   CMP = $signed(A) < $signed(B);
      `ALU_GE:   CMP = $signed(A) >= $signed(B);
      `ALU_LTU:  CMP = A < B;
      `ALU_GEU:  CMP = A >= B;
      default: begin
        Q   = 32'd0;
        CMP = 1'b0;
      end
    endcase
  end
endmodule
