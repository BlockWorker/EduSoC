`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: cache
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - instruction cache
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module cache #(parameter INDEX_BITS = 6) (
    input clk,
    input res,
    
    input cached_instr_req,
    input [31:0] cached_instr_adr,
    output reg cached_instr_valid,
    output reg [31:0] cached_instr_read,
    
    output reg instr_req,
    output reg [31:0] instr_adr,
    input instr_valid,
    input [31:0] instr_read
    );
    
    reg [31:0] lines [(2 ** INDEX_BITS - 1):0];
    reg [(29 - INDEX_BITS):0] tags [(2 ** INDEX_BITS - 1):0];
    reg [(2 ** INDEX_BITS - 1):0] valids;
    wire hit;
    wire [(INDEX_BITS - 1):0] index;
    reg [1:0] state;
    integer i;
    
    assign index = cached_instr_adr[(INDEX_BITS + 1):2];
    assign hit = valids[index] && (tags[index] == cached_instr_adr[31:(INDEX_BITS + 2)]);
    
    always @(posedge clk) begin
        if (res) begin
            valids <= {(2 ** INDEX_BITS){1'b0}};
            for (i = 0; i < 2 ** INDEX_BITS; i=i+1) begin
                lines[index] <= 32'b0;
                tags[index] <= {(30 - INDEX_BITS){1'b0}};
            end
        end
        else if (instr_valid) begin
            lines[index] <= instr_read;
            tags[index] <= cached_instr_adr[31:(INDEX_BITS + 2)];
            valids[index] <= 1'b1;
        end
    end
    
    always @(posedge clk) begin
        if (res) state <= `CACHE_STATE_WAIT;
        else begin
            case (state)
                `CACHE_STATE_WAIT: if (cached_instr_req) begin
                    if (hit) state <= `CACHE_STATE_FULFILL;
                    else state <= `CACHE_STATE_REQUEST;
                end
                `CACHE_STATE_REQUEST: if (instr_valid) state <= `CACHE_STATE_FULFILL;
                `CACHE_STATE_FULFILL: if (~cached_instr_req) state <= `CACHE_STATE_WAIT;
                default: state <= `CACHE_STATE_WAIT;
            endcase
        end
    end
    
    always @(*) begin
        case (state)
            `CACHE_STATE_REQUEST: begin
                cached_instr_valid = instr_valid;
                cached_instr_read = instr_read;
                instr_req = 1'b1;
                instr_adr = cached_instr_adr;
            end
            `CACHE_STATE_FULFILL: begin
                cached_instr_valid = 1'b1;
                cached_instr_read = lines[index];
                instr_req = 1'b0;
                instr_adr = 32'b0;
            end
            default: begin
                cached_instr_valid = 1'b0;
                cached_instr_read = 32'b0;
                instr_req = 1'b0;
                instr_adr = 32'b0;
            end
        endcase
    end
    
endmodule
