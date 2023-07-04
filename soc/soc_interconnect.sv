`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 24.06.2023 19:34:47
// Design Name: 
// Module Name: soc_interconnect
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Memory bus interconnect for the SoC, with a configurable number of slave bus connections.
//              Master bus connections are fixed to the following, with round-robin deciding between low priority requests:
//                  - High-priority bus (index 0) (for external programming with UART)
//                  - Low-priority bus (core instruction bus)
//                  - Low-priority bus (core data bus)
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_interconnect #(
        parameter SLAVE_COUNT = 1,
        parameter integer SLAVE_START_ADDRESSES [SLAVE_COUNT-1:0] = { '0 },
        parameter integer SLAVE_END_ADDRESSES [SLAVE_COUNT-1:0] = { 'h1000 }
    ) (
        input clk,
        input res,
        
        SoC_MemBus.Slave master_buses [2:0], //high-priority bus (external) at index 0, two low-priority buses (instruction, data) at indices 1 and 2
        
        SoC_MemBus.Master slave_buses [SLAVE_COUNT-1:0] //slave buses
    );
    
    localparam SLAVE_INDEX_WIDTH = $clog2(SLAVE_COUNT);
    
    wire [SLAVE_COUNT-1:0] slave_select [2:0]; //which slave is selected for each master (one-hot)
    wire [2:0] address_valid; //whether each master's address is valid for any slave
    
    wire [SLAVE_COUNT-1:0] slave_granted [2:0]; //which slave is granted to each master (one-hot)
    wire [SLAVE_INDEX_WIDTH-1:0] slave_index [2:0]; //index of slave granted to each master, if there is one (binary)
    wire [2:0] slave_granted_any; //for each master: whether any slave is granted to it
    
    wire [SLAVE_INDEX_WIDTH-1:0] slave_index_gen [3*SLAVE_COUNT-1:0]; //helper array for index generation
    
    //master outputs, extracted from buses for multiplexing
    wire [31:0] master_addresses [2:0];
    wire [31:0] master_write_data [2:0];
    wire master_write_enables [2:0];
    wire [3:0] master_byte_enables [2:0];
    
    //slave outputs, extracted from buses for multiplexing
    wire [31:0] slave_read_data [SLAVE_COUNT-1:0];
    wire slave_valids [SLAVE_COUNT-1:0];
    
    generate
        genvar i, j, k;
        
        //for each master
        for (j = 0; j < 3; j = j + 1) begin : master_gen
            for (k = 0; k < SLAVE_INDEX_WIDTH; k = k + 1) begin : slave_index_reduction //reduce slave index from generator bitstrings to index, bitwise
                wire [SLAVE_COUNT-1:0] bitvector;
                for (i = 0; i < SLAVE_COUNT; i = i + 1) begin //create vector of k-th bit of index from individual generator bitstrings' k-th bit
                    assign bitvector[i] = slave_index_gen[3*i+j][k];
                end
                assign slave_index[j][k] = |bitvector; //reduce to index bit using OR
            end
            
            assign address_valid[j] = |(slave_select[j]); //address is valid if any slave is selected
            assign slave_granted_any[j] = |(slave_granted[j]); //is any slave granted?
            
            //extract bus outputs
            assign master_addresses[j] = master_buses[j].addr;
            assign master_write_data[j] = master_buses[j].write_data;
            assign master_write_enables[j] = master_buses[j].write_en;
            assign master_byte_enables[j] = master_buses[j].byte_en;
            
            //connect granted slave outputs to master inputs, if any granted
            assign master_buses[j].read_data = slave_granted_any[j] ? slave_read_data[slave_index[j]] : 32'bZ; //read data defaults to Hi-Z if unconnected
                //special case for valid: default to 0 for valid address (waiting for slave), else immediately validate request (invalid address fallback)
            assign master_buses[j].valid = slave_granted_any[j] ? slave_valids[slave_index[j]] : (address_valid[j] ? 1'b0 : master_buses[j].req);
        end
        
        //for each slave
        for (i = 0; i < SLAVE_COUNT; i = i + 1) begin : slave_gen
            wire [2:0] requests; //which masters are requesting access to slave i
            wire [2:0] grant; //which master is granted slave i
            wire [1:0] master_grant_index = (grant == 3'b100 ? 2'd2 : (grant == 3'b010 ? 2'd1 : 2'd0)); //index of master that is granted slave i, if there is any
            wire master_grant_any = |grant; //whether any master is granted slave i
            
            for (j = 0; j < 3; j = j + 1) begin
                assign slave_select[j][i] = (master_buses[j].addr >= SLAVE_START_ADDRESSES[i] && master_buses[j].addr < SLAVE_END_ADDRESSES[i]);
                assign requests[j] = master_buses[j].req && slave_select[j][i];
                
                assign slave_granted[j][i] = grant[j];
                assign slave_index_gen[3*i+j] = slave_granted[j][i] ? i : '0; //create generator bitstring for index - exactly i if i is granted, otherwise 0
            end
            
            soc_rrprio_encoder conflict_resolver (
                .clk(clk),
                .res(res),
                .requests(requests),
                .grant(grant)
            );
            
            //extract bus outputs
            assign slave_read_data[i] = slave_buses[i].read_data;
            assign slave_valids[i] = slave_buses[i].valid;
            
            //connect granted master outputs to slave inputs, if any granted
            assign slave_buses[i].addr = master_grant_any ? master_addresses[master_grant_index] : 32'b0;
            assign slave_buses[i].write_data = master_grant_any ? master_write_data[master_grant_index] : 32'b0;
            assign slave_buses[i].write_en = master_grant_any ? master_write_enables[master_grant_index] : 0;
            assign slave_buses[i].byte_en = master_grant_any ? master_byte_enables[master_grant_index] : 4'b0;
            assign slave_buses[i].req = master_grant_any; //any master request granted means slave gets a request
        end
    endgenerate
    
endmodule
