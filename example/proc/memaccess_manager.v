`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date:
// Design Name: 
// Module Name: mamgr
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - memory access manager for unaligned memory access
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module memaccess_manager(
    input CLK,
    input RES,
    input [2:0] TYPE,
    input DATA_REQ,
    input DATA_WRITE_ENABLE,
    output reg DATA_VALID,
    input [31:0] DATA_ADR,
    output reg [31:0] DATA_READ,
    input [31:0] DATA_WRITE,
    output reg MEM_REQ,
    output reg MEM_WRITE_ENABLE,
    input MEM_VALID,
    output reg [31:0] MEM_ADR,
    input [31:0] MEM_READ,
    output reg [31:0] MEM_WRITE,
    output reg [3:0] MEM_BE
    );
    
    reg [2:0] state;
    
    reg write_enable;
    reg [2:0] type;
    reg [31:0] adr;
    reg [31:0] write_tmp;
    
    reg [31:0] a;
    reg [31:0] b;
    wire [31:0] adr_a = {adr[31:2], 2'd0};
    wire [31:0] adr_b = adr_a + 32'd4;
    
    wire [4:0] type_exact = {type == 3'b100, type == 3'b000, type == 3'b101, type == 3'b001, type == 3'b010};
    wire [2:0] type_fuzzy = {type_exact[4] || type_exact[3], type_exact[2] || type_exact[1], type_exact[0]};
    
    wire [7:0] be;
    wire [31:0] store_data;
    wire [31:0] read_data;
    
    table3x4_sel be_sel(.row(type_fuzzy),
                        .col(adr[1:0]),
                        .selected(be),
                        .in_0x0(8'b00001111),
                        .in_0x1(8'b00011110),
                        .in_0x2(8'b00111100),
                        .in_0x3(8'b01111000),
                        .in_1x0(8'b00000011),
                        .in_1x1(8'b00000110),
                        .in_1x2(8'b00001100),
                        .in_1x3(8'b00011000),
                        .in_2x0(8'b00000001),
                        .in_2x1(8'b00000010),
                        .in_2x2(8'b00000100),
                        .in_2x3(8'b00001000));
                        
    table3x4_sel  store_sel(.row(type_fuzzy),
                            .col(adr[1:0]),
                            .selected(store_data),
                            .in_0x0(write_tmp),
                            .in_0x1({write_tmp[23:0], write_tmp[31:24]}),
                            .in_0x2({write_tmp[15:0], write_tmp[31:16]}),
                            .in_0x3({write_tmp[7:0], write_tmp[31:8]}),
                            .in_1x0({16'd0, write_tmp[15:0]}),
                            .in_1x1({8'd0, write_tmp[15:0], 8'd0}),
                            .in_1x2({write_tmp[15:0], 16'd0}),
                            .in_1x3({write_tmp[7:0], 16'd0, write_tmp[15:8]}),
                            .in_2x0({24'd0, write_tmp[7:0]}),
                            .in_2x1({16'd0, write_tmp[7:0], 8'd0}),
                            .in_2x2({8'd0, write_tmp[7:0], 16'd0}),
                            .in_2x3({write_tmp[7:0], 24'd0}));
    
    table5x4_sel   read_sel(.row(type_exact),
                            .col(adr[1:0]),
                            .selected(read_data),
                            .in_0x0(a),
                            .in_0x1({b[7:0], a[31:8]}),
                            .in_0x2({b[15:0], a[31:16]}),
                            .in_0x3({b[23:0], a[31:24]}),
                            .in_1x0({{16{a[15]}}, a[15:0]}),
                            .in_1x1({{16{a[23]}}, a[23:8]}),
                            .in_1x2({{16{a[31]}}, a[31:16]}),
                            .in_1x3({{16{b[7]}}, b[7:0], a[31:24]}),
                            .in_2x0({16'd0, a[15:0]}),
                            .in_2x1({16'd0, a[23:8]}),
                            .in_2x2({16'd0, a[31:16]}),
                            .in_2x3({16'd0, b[7:0], a[31:24]}),
                            .in_3x0({{24{a[7]}}, a[7:0]}),
                            .in_3x1({{24{a[15]}}, a[15:8]}),
                            .in_3x2({{24{a[23]}}, a[23:16]}),
                            .in_3x3({{24{a[31]}}, a[31:24]}),
                            .in_4x0({24'd0, a[7:0]}),
                            .in_4x1({24'd0, a[15:8]}),
                            .in_4x2({24'd0, a[23:16]}),
                            .in_4x3({24'd0, a[31:24]}));
        
    always @(posedge CLK) begin
        if (RES) state <= `MEM_STATE_WAIT;
        else case (state)
            `MEM_STATE_WAIT: if (DATA_REQ) begin
                write_enable <= DATA_WRITE_ENABLE;
                type <= TYPE;
                adr <= DATA_ADR;
                write_tmp <= DATA_WRITE;
                state <= `MEM_STATE_REQ_A;
            end
            `MEM_STATE_REQ_A: begin
                if (MEM_VALID) begin
                    if (~write_enable) a <= MEM_READ;
                    
                    if ((type_fuzzy[0] && adr[1:0] != 2'b00) || (type_fuzzy[1] && adr[1:0] == 2'b11)) state <= `MEM_STATE_REQ_B;
                    else state <= `MEM_STATE_FULFILL;
                end
            end
            `MEM_STATE_REQ_B: begin
                if (MEM_VALID) begin
                    if (~write_enable) b <= MEM_READ;
                
                    state <= `MEM_STATE_FULFILL;
                end
            end
            `MEM_STATE_FULFILL: if (~DATA_REQ) state <= `MEM_STATE_WAIT;
            default: state <= `MEM_STATE_WAIT;
        endcase
    end
    
    always @(*) begin
        case (state)
            `MEM_STATE_REQ_A: begin
                DATA_VALID = 1'b0;
                DATA_READ = 32'd0;
                MEM_REQ = 1'b1;
                MEM_WRITE_ENABLE = write_enable;
                MEM_ADR = adr_a;
                MEM_WRITE = store_data;
                MEM_BE = be[3:0];
            end
            `MEM_STATE_REQ_B: begin
                DATA_VALID = 1'b0;
                DATA_READ = 32'd0;
                MEM_REQ = 1'b1;
                MEM_WRITE_ENABLE = write_enable;
                MEM_ADR = adr_b;
                MEM_WRITE = store_data;
                MEM_BE = be[7:4];
            end
            `MEM_STATE_FULFILL: begin
                DATA_VALID = 1'b1;
                DATA_READ = write_enable ? 32'd0 : read_data;
                MEM_REQ = 1'b0;
                MEM_WRITE_ENABLE = 1'b0;
                MEM_ADR = 32'd0;
                MEM_WRITE = 32'd0;
                MEM_BE = 4'd0;
            end
            default: begin
                DATA_VALID = 1'b0;
                DATA_READ = 32'd0;
                MEM_REQ = 1'b0;
                MEM_WRITE_ENABLE = 1'b0;
                MEM_ADR = 32'd0;
                MEM_WRITE = 32'd0;
                MEM_BE = 4'd0;
            end
        endcase
    end    
    
endmodule
