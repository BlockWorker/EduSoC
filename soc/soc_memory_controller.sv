`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 22.06.2023 13:55:05
// Design Name: 
// Module Name: soc_memory_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Controller for block memory modules, implementing the SoC memory protocol for the given memory size and latency.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_memory_controller #(
        parameter ADDR_WIDTH = 12, //total address width (assuming LSB addresses bytes)
        parameter LATENCY = 1 //additional latency of memory block (on top of inherent 1-cycle latency)
    ) (
        input clk,
        input res,
        
        SoC_MemBus.Slave bus,
        
        input [31:0] mem_data_out,
        output reg [ADDR_WIDTH-3:0] word_addr_out,
        output [3:0] mem_we
    );
    
    localparam WORD_ADDR_WIDTH = ADDR_WIDTH - 2;
    
    wire [WORD_ADDR_WIDTH-1:0] word_addr = bus.req ? bus.addr[ADDR_WIDTH-1:2] : '0; //currently requested word address, zero if no request
    reg [LATENCY+1:0] valid_delay = '0; //shift register to delay valid signal according to memory latency
    wire ack = valid_delay[0]; //whether the current request (if present) has been received/acknowledged
    wire addr_stable = (word_addr_out == word_addr); //whether the address is stable, i.e. the same as the latched address
    reg write_en_latched; //latched state of write enable signal
    wire write_en_stable = (write_en_latched == bus.write_en); //whether write enable signal is stable, i.e. the same as the latched state
    wire write = bus.req && bus.write_en && write_en_latched && ack && ~bus.valid && addr_stable && valid_delay[LATENCY]; //whether to enable actual memory write (one clock cycle before valid)
    
    assign mem_we = write ? bus.byte_en : 4'b0; //propagate write-enabled bytes once acknowledged, until latency passed
    assign bus.read_data = bus.valid ? mem_data_out : 32'bZ; //data output defaults to High-Z until request has been processed and latency passed
    assign bus.valid = bus.req && ack && valid_delay[LATENCY+1] && addr_stable && write_en_stable;
    
    always @(posedge clk) begin
        if (res || ~bus.req) begin //reset or no request: clear valid shifter and latched address
            valid_delay <= '0;
            word_addr_out <= '0;
            write_en_latched <= 0;
        end else if (~addr_stable || ~write_en_stable) begin //request and new address or write state: latch address, init valid shifter
            word_addr_out <= word_addr;
            write_en_latched <= bus.write_en;
            valid_delay <= {{LATENCY+1{1'b0}}, 1'b1};
        end else begin //request and stable address: shift valid bits
            valid_delay <= {valid_delay[LATENCY:0], 1'b1};
        end
    end
    
endmodule
