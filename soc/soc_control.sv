`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.06.2023 12:10:22
// Design Name: 
// Module Name: soc_control
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: SoC controller peripheral. Allows resets to be forced, the core to be halted, and handles interrupt control.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "soc_defines.sv"


module soc_control #(
        parameter BUS_LATENCY = 1
    ) (
        input clk,
        input raw_res,
        
        output core_halt,
        output core_res,
        output soc_res,
        output [15:0] control_flags,
        
        input [31:0] int_triggers,
        
        SoC_MemBus.Slave mem_bus,
        SoC_InterruptBus.Generator int_bus
    );
    
    reg [31:0] int_clears;
    reg [31:0] int_enables;
    wire [31:0] asserted_ints;
    reg [31:0] control_register;
    
    wire [31:0] addr;
    wire [7:0] register_addr = addr[11:4]; //local register address
    wire [1:0] register_type = addr[3:2]; //register access type
    reg [31:0] register_value;
    wire [31:0] register_write;
    wire write_enabled;
    
    //SoC interrupt controller
    soc_interrupt_controller int_ctl (
        .clk(clk),
        .res(soc_res),
        .int_bus(int_bus),
        .enabled_int(control_register[3] ? int_enables : 32'b0), //mask int enables with global int enable
        .int_clears(int_clears),
        .int_triggers(int_triggers),
        .asserted_ints(asserted_ints)
    );
    
    //memory bus controller
    soc_peripheral_controller #(
        .LATENCY(BUS_LATENCY)
    ) per_ctl (
        .clk(clk),
        .res(soc_res),
        .bus(mem_bus),
        .data_out(register_value),
        .unchanged_value(register_value),
        .addr_out(addr),
        .write_data(register_write),
        .we(write_enabled)
    );
    
    //control register fanout
    assign core_halt = control_register[0];
    assign core_res = raw_res || control_register[1];
    assign soc_res = raw_res || control_register[2];
    assign control_flags = control_register[31:16];
    
    initial control_register <= 32'b0;
    
    //register read value assignment
    always @(*) begin
        register_value = 32'b0;
        
        if (register_type == `REG_TYPE_MAIN) begin
            case (register_addr)
                `REG_SOCCTL_CONTROL: register_value = control_register;
                `REG_SOCCTL_INT_EN: register_value = int_enables;
                `REG_SOCCTL_INT_FLAGS: register_value = asserted_ints;
            endcase
        end
    end
    
    //register writing
    always @(posedge clk) begin
        int_clears <= 32'b0; //reset clears, if any set from previous clock cycle (since clear should have happened now)
    
        if (soc_res) begin
            int_enables <= 32'b0;
            control_register[15:0] <= 16'h8; //interrupts globally enabled at reset
        end else if (write_enabled) begin
            case (register_addr)
                `REG_SOCCTL_CONTROL: begin //write to control register, ignore reserved bits
                    control_register <= `REG_WRITEVAL(control_register, register_write, register_type) & 32'hFFFF000F;
                end
                `REG_SOCCTL_INT_EN: begin //write to interrupt enable register
                    int_enables <= `REG_WRITEVAL(int_enables, register_write, register_type);
                end
                `REG_SOCCTL_INT_FLAGS: begin //write to interrupt flags register: can only be cleared
                    if (register_type == `REG_TYPE_MAIN) int_clears <= ~register_write;
                    else if (register_type == `REG_TYPE_CLR || register_type == `REG_TYPE_INV) int_clears <= register_write;
                end
            endcase
        end
    end
    
endmodule
