`timescale 1ns / 1ps
module MUX_4x1_32(
    input [31:0] I0,
    input [31:0] I1,
    input [31:0] I2,
    input [31:0] I3,
    input [1:0] S,
    output [31:0] Y
    );
    
    assign Y = S[1] ? (S[0] ? I3 : I2) : (S[0] ? I1 : I0);
endmodule
