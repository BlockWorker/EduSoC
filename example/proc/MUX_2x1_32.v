`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.09.2018 10:18:41
// Design Name: 
// Module Name: MUX_2x1_32
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


module MUX_2x1_32(
    input [31:0] I0,
    input [31:0] I1,
    input S,
    output [31:0] Y
    );
    assign Y= (S==1'b0) ? I0 : I1;
endmodule
