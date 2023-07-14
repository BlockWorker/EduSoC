`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 25.06.2023 13:04:38
// Design Name: 
// Module Name: interconnect_tb
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


module interconnect_tb();

    reg clk, res;

    SoC_MemBus master_0(), master_1(), master_2();
    
    SoC_MemBus slave_0(), slave_1(), slave_2(), slave_3();
    
    localparam integer START_ADDR [3:0] = { 'h10000000, 'h50000000, 'h90000000, 'hD0000000 };
    localparam integer END_ADDR [3:0] = { 'h40000000, 'h80000000, 'hC0000000, 'hFF000000 };
    
    soc_interconnect #(
        .SLAVE_COUNT(4),
        .SLAVE_START_ADDRESSES(START_ADDR),
        .SLAVE_END_ADDRESSES(END_ADDR)
    ) dut (
        .clk(clk),
        .res(res),
        .master_buses({master_2.Slave, master_1.Slave, master_0.Slave}),
        .slave_buses({slave_3.Master, slave_2.Master, slave_1.Master, slave_0.Master})
    );
    
    class Request;
        randc bit [7:0] addr;
        rand bit [31:0] write_data;
        rand bit write_en;
        rand bit [3:0] byte_en;
        rand bit [2:0] active;
    endclass;
    
    //clock init and reset
    initial begin
        clk <= 0;
        res <= 1;
        @(posedge clk);
        @(posedge clk);
        res <= 0;
    end
    
    //clock gen
    always #1 clk <= ~clk;
    
    //dummy memory controllers for all slaves
    soc_memory_controller #(
        .LATENCY(10)
    ) slave_0_con (
        .clk(clk),
        .res(res),
        .bus(slave_0.Slave),
        .mem_data_out(32'hf0f0f0f0)
    );
    soc_memory_controller #(
        .ADDR_WIDTH(32),
        .LATENCY(10)
    ) slave_1_con (
        .clk(clk),
        .res(res),
        .bus(slave_1.Slave),
        .mem_data_out(32'he1e1e1e1)
    );
    soc_memory_controller #(
        .ADDR_WIDTH(32),
        .LATENCY(10)
    ) slave_2_con (
        .clk(clk),
        .res(res),
        .bus(slave_2.Slave),
        .mem_data_out(32'hd2d2d2d2)
    );
    soc_peripheral_controller #(
        .LATENCY(10)
    ) slave_3_con (
        .clk(clk),
        .res(res),
        .bus(slave_3.Slave),
        .data_out(32'hc3c3c3c3)
    );
    
    //automatic request cancellation upon valid for all masters
    always @(posedge clk) begin
        if (master_0.valid) master_0.req <= 0;
        if (master_1.valid) master_1.req <= 0;
        if (master_2.valid) master_2.req <= 0;
    end
    
    //randomized requests
    Request requests[3];
    initial begin
        master_0.addr <= 32'b0;
        master_0.write_data <= 32'b0;
        master_0.write_en <= 0;
        master_0.byte_en <= 4'b0;
        master_0.req <= 0;
        master_1.addr <= 32'b0;
        master_1.write_data <= 32'b0;
        master_1.write_en <= 0;
        master_1.byte_en <= 4'b0;
        master_1.req <= 0;
        master_2.addr <= 32'b0;
        master_2.write_data <= 32'b0;
        master_2.write_en <= 0;
        master_2.byte_en <= 4'b0;
        master_2.req <= 0;
        
        requests[0] = new();
        requests[1] = new();
        requests[2] = new();
    end
    
    always @(posedge clk) begin
        if (~master_0.req) begin
            requests[0].randomize();
            if (requests[0].active == '0) begin
                master_0.addr <= {requests[0].addr, 24'b0};
                master_0.write_data <= requests[0].write_data;
                master_0.write_en <= requests[0].write_en;
                master_0.byte_en <= requests[0].byte_en;
                master_0.req <= 1;
            end
        end
        if (~master_1.req) begin
            requests[1].randomize();
            if (requests[1].active == '0) begin
                master_1.addr <= {requests[1].addr, 24'b0};
                master_1.write_data <= requests[1].write_data;
                master_1.write_en <= requests[1].write_en;
                master_1.byte_en <= requests[1].byte_en;
                master_1.req <= 1;
            end
        end
        if (~master_2.req) begin
            requests[2].randomize();
            if (requests[2].active == '0) begin
                master_2.addr <= {requests[2].addr, 24'b0};
                master_2.write_data <= requests[2].write_data;
                master_2.write_en <= requests[2].write_en;
                master_2.byte_en <= requests[2].byte_en;
                master_2.req <= 1;
            end
        end
    end    

endmodule
