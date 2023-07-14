//`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: 
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.11.2018 16:46:02
// Design Name: 
// Module Name: table4x3_sel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module table3x4_sel (
    input [1:0] col,
    input [2:0] row,
    input [31:0] in_0x0,
    input [31:0] in_0x1,
    input [31:0] in_0x2,
    input [31:0] in_0x3,
    input [31:0] in_1x0,
    input [31:0] in_1x1,
    input [31:0] in_1x2,
    input [31:0] in_1x3,
    input [31:0] in_2x0,
    input [31:0] in_2x1,
    input [31:0] in_2x2,
    input [31:0] in_2x3,
    output reg [31:0] selected
);

  always@(col, row, in_0x0,in_0x1,in_0x2,in_0x3, in_1x0,in_1x1,in_1x2,in_1x3, in_2x0,in_2x1,in_2x2,in_2x3)
begin
    selected = 32'hDEADBEEF;
    case (col)
      2'b00: selected = row[0] ? in_0x0 : row[1] ? in_1x0 : row[2] ? in_2x0 : 32'hDEADBEEF;
      2'b01: selected = row[0] ? in_0x1 : row[1] ? in_1x1 : row[2] ? in_2x1 : 32'hDEADBEEF;
      2'b10: selected = row[0] ? in_0x2 : row[1] ? in_1x2 : row[2] ? in_2x2 : 32'hDEADBEEF;
      2'b11: selected = row[0] ? in_0x3 : row[1] ? in_1x3 : row[2] ? in_2x3 : 32'hDEADBEEF;
    endcase
  end
endmodule
