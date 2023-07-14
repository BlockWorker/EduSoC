`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 23.06.2023 22:43:59
// Design Name: 
// Module Name: soc_crc32
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Configurable CRC32 engine. Default configuration is CRC-32C.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_crc32 #(
        parameter POLYNOMIAL = 32'h1EDC6F41,
        parameter INPUT_WIDTH = 8,
        parameter LSBFIRST = 1,
        parameter OUT_REFLECT = 1,
        parameter INIT = 32'hFFFFFFFF,
        parameter FINAL_XOR = 32'hFFFFFFFF
    ) (
        input clk,
        input res,
        
        input [INPUT_WIDTH-1:0] in_data,
        input process_data,
        output [31:0] out_crc,
        output ready
    );
    
    reg [INPUT_WIDTH-1:0] remaining_bits;
    reg [INPUT_WIDTH-1:0] data_buffer;
    reg [31:0] crc;
    wire shift_in = (LSBFIRST ? data_buffer[0] : data_buffer[INPUT_WIDTH-1]) ^ crc[31];
    
    generate
        if (OUT_REFLECT) begin
            genvar i;
            for (i = 0; i < 32; i = i + 1) begin
                assign out_crc[i] = crc[31 - i] ^ FINAL_XOR[i];
            end
        end else begin
            assign out_crc = crc ^ FINAL_XOR;
        end
    endgenerate
    
    assign ready = ~remaining_bits[0];
    
    always @(posedge clk) begin
        if (res) begin
            crc <= INIT;
            remaining_bits <= {INPUT_WIDTH{1'b0}};
            data_buffer <= {INPUT_WIDTH{1'b0}};
        end else begin
            if (ready) begin //no current calculation: do nothing unless calculation requested
                if (process_data) begin //new data to be processed: copy to buffer and begin calculation
                    remaining_bits <= {INPUT_WIDTH{1'b1}};
                    data_buffer <= in_data;
                end
            end else begin //calculation ongoing
                if (shift_in) begin //actual CRC shifting, with polynomial XOR if required
                    crc <= {crc[30:0] ^ POLYNOMIAL[31:1], 1'b1};
                end else begin
                    crc <= {crc[30:0], 1'b0};
                end
                
                remaining_bits <= remaining_bits >> 1; //continue to next bit of input
                if (LSBFIRST) data_buffer <= data_buffer >> 1;
                else data_buffer <= data_buffer << 1;
            end
        end
    end    
    
endmodule
