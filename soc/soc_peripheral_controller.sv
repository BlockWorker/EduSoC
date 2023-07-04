`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 29.06.2023 10:39:21
// Design Name: 
// Module Name: soc_peripheral_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Controller for peripheral modules, implementing the SoC memory protocol for the given address space and latency.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "soc_defines.sv"


module soc_peripheral_controller #(
        parameter LATENCY = 1 //additional latency of peripheral interface (on top of inherent 1-cycle latency)
    ) (
        input clk,
        input res,
        
        SoC_MemBus.Slave bus,
        
        input [31:0] data_out,
        input [31:0] unchanged_value,
        output reg [31:0] addr_out,
        output [31:0] write_data,
        output we
    );
    
    wire [31:0] req_addr = bus.req ? bus.addr : '0; //currently requested address, zero if no request
    reg [LATENCY+2:0] valid_delay = '0; //shift register to delay valid signal according to memory latency
    wire ack = valid_delay[0]; //whether the current request (if present) has been received/acknowledged
    wire addr_stable = (addr_out == req_addr); //whether the address is stable, i.e. the same as the latched address
    reg write_en_latched; //latched state of write enable signal
    wire write_en_stable = (write_en_latched == bus.write_en); //whether write enable signal is stable, i.e. the same as the latched state
    reg [31:0] read_data_latched; //latched read value
    
    assign we = bus.req && bus.write_en && write_en_latched && ack && ~bus.valid && addr_stable && valid_delay[LATENCY]; //whether to enable actual memory write (one clock cycle before valid)

    assign bus.read_data = bus.valid ? (valid_delay[LATENCY+2] ? read_data_latched : data_out) : 32'bZ; //data output defaults to High-Z until request has been processed and latency passed, and latched data after that
    assign bus.valid = bus.req && ack && valid_delay[LATENCY+1] && addr_stable && write_en_stable;
    
    assign write_data = {bus.byte_en[3] ? bus.write_data[31:24] : unchanged_value[31:24], //select write bytes or unchanged bytes based on byte enable
                         bus.byte_en[2] ? bus.write_data[23:16] : unchanged_value[23:16],
                         bus.byte_en[1] ? bus.write_data[15:8] : unchanged_value[15:8],
                         bus.byte_en[0] ? bus.write_data[7:0] : unchanged_value[7:0]};
    
    always @(posedge clk) begin
        if (res || ~bus.req) begin //reset or no request: clear valid shifter and latched address
            valid_delay <= '0;
            addr_out <= '0;
            write_en_latched <= 0;
            read_data_latched <= 0;
        end else if (~addr_stable || ~write_en_stable) begin //request and new address or write state: latch address, init valid shifter
            addr_out <= req_addr;
            write_en_latched <= bus.write_en;
            valid_delay <= {{LATENCY+2{1'b0}}, 1'b1};
        end else begin //request and stable address: shift valid bits
            valid_delay <= {valid_delay[LATENCY+1:0], 1'b1};
        end
        
        if (bus.valid && ~valid_delay[LATENCY+2]) begin //latch read data on first valid cycle
            read_data_latched <= bus.read_data;
        end
    end
    
endmodule
