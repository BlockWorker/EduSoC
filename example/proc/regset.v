//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: regset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - register set
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regset (
    input [31:0] D,
    input [4:0] A_D,
    input [4:0] A_Q0,
    input [4:0] A_Q1,
    input write_enable,
    input RES,
    input CLK,
    output reg [31:0] Q0,
    output reg [31:0] Q1
);

  reg [31:0] data[31:1];
  integer i;

  always @(*) begin
    if (A_Q0 == 5'd0) Q0 = 32'd0;  //output zero for zero register
    else Q0 = data[A_Q0];
  end

  always @(*) begin
    if (A_Q1 == 5'd0) Q1 = 32'd0;  //output zero for zero register
    else Q1 = data[A_Q1];
  end

  always @(posedge CLK) begin
    if (RES) for (i = 1; i < 32; i = i + 1) data[i] <= 32'd0;  //reset all registers
    else if (write_enable && A_D != 5'd0)
      data[A_D] <= D;  //write register unless zero register is selected
  end

endmodule
