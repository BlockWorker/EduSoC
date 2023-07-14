`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: 
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 24.09.2018 10:19:57
// Design Name: 
// Module Name: REG_DR_32
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


module REG_DR_32(
    input [31:0] D,
    output [31:0] Q,
    input CLK,
    input RES
    );
    reg [31:0] Q_tmp=32'd0;
    assign Q=Q_tmp;
    always @(posedge CLK)
    begin
      if(RES==1'b1)
        Q_tmp<=32'd0;
      else
        Q_tmp<=D;      
    end
endmodule
