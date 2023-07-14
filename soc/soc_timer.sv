`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.06.2023 12:10:22
// Design Name: 
// Module Name: soc_timer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Timer module for the SoC. Supports up to 16 independently configurable timers.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "soc_defines.sv"


module soc_timer #(
        parameter BUS_LATENCY = 1,
        parameter TIMER_COUNT = 1 //how many independent timers are created, up to 16
    ) (
        input clk,
        input res,
        
        output [31:0] timer_counts [TIMER_COUNT-1:0],
        
        output reg interrupt_trigger,
        
        SoC_MemBus.Slave mem_bus
    );
    
    initial assert (TIMER_COUNT <= 16) else $error("Timer module only supports up to 16 timers.");
    
    wire [31:0] addr;
    wire [3:0] register_index = addr[11:8]; //index of selected PWM module
    wire [3:0] register_addr = addr[7:4]; //local register address within selected module
    wire [1:0] register_type = addr[3:2]; //register access type
    reg [31:0] register_value;
    wire [31:0] register_write;
    wire write_enabled;
    
    reg [31:0] interrupt_status;
    
    reg [31:0] controls [TIMER_COUNT-1:0];
    reg [31:0] counts [TIMER_COUNT-1:0];
    reg [31:0] periods [TIMER_COUNT-1:0];
    wire [31:0] next_counts [TIMER_COUNT-1:0];
    
    //memory bus controller
    soc_peripheral_controller #(
        .LATENCY(BUS_LATENCY)
    ) per_ctl (
        .clk(clk),
        .res(res),
        .bus(mem_bus),
        .data_out(register_value),
        .unchanged_value(register_value),
        .addr_out(addr),
        .write_data(register_write),
        .we(write_enabled)
    );
    
    //increment and output generation
    generate
        genvar i;
        
        for (i = 0; i < TIMER_COUNT; i++) begin
            assign next_counts[i] = counts[i] + 32'd1;
            
            assign timer_counts[i] = counts[i];
        end
    endgenerate
    
    //register read value assignment
    always @(*) begin
        register_value = 32'b0;
        
        if (register_type == `REG_TYPE_MAIN) begin
            if (register_addr == `REG_TIMER_INT_STATUS) begin //int status is a global register, don't care about port index
                register_value = interrupt_status;
            end else if (register_index < TIMER_COUNT) begin
                case (register_addr)
                    `REG_TIMER_CONTROL: register_value = controls[register_index];
                    `REG_TIMER_COUNT: register_value = counts[register_index];
                    `REG_TIMER_PERIOD: register_value = periods[register_index];
                endcase
            end
        end
    end
    
    //register writing and tick/interrupt handling
    always @(posedge clk) begin
        interrupt_trigger <= 0; //always reset the interrupt trigger - only high for one clock cycle per event
    
        if (res) begin
            interrupt_status <= 32'b0;
        
            for (int i = 0; i < TIMER_COUNT; i++) begin
                controls[i] <= 32'b0;
                counts[i] <= 32'b0;
                periods[i] <= 32'b0;
            end
        end else begin
            for (int i = 0; i < TIMER_COUNT; i++) begin
                if (controls[i][8] || ~controls[i][0]) begin //restart timer, or timer disabled
                    counts[i] <= 32'b0;
                end else if (next_counts[i] == periods[i]) begin //timer period reached
                    counts[i] <= 32'b0;
                    if (controls[i][1]) begin //disable timer if oneshot mode is enabled
                        controls[i][0] <= 0;
                    end
                    if (controls[i][2]) begin //trigger interrupt if interrupt enabled
                        interrupt_status[i] <= 1;
                        interrupt_trigger <= 1;
                    end
                end else begin //timer enabled but period not reached yet: just increment
                    counts[i] <= next_counts[i];
                end
                
                controls[i][8] <= 0; //clear timer reset (to allow it to keep running after being reset)
            end
        
            if (write_enabled) begin
                if (register_addr == `REG_TIMER_INT_STATUS) begin //int status is a global register, don't care about port index, clear only
                    if (register_type == `REG_TYPE_MAIN) interrupt_status <= interrupt_status & register_write;
                    else if (register_type == `REG_TYPE_CLR || register_type == `REG_TYPE_INV) interrupt_status <= interrupt_status & ~register_write;
                end else if (register_index < TIMER_COUNT) begin
                    case (register_addr)
                        `REG_TIMER_CONTROL: begin //write to control register, ignore reserved bits
                            controls[register_index] <= `REG_WRITEVAL(controls[register_index], register_write, register_type) & 32'h107;
                        end
                        `REG_TIMER_PERIOD: begin //write to period register
                            periods[register_index] <= `REG_WRITEVAL(periods[register_index], register_write, register_type);
                            counts[register_index] <= 32'b0; //period change resets count to zero without triggering interrupt
                        end
                    endcase
                end
            end
        end
    end
    
endmodule
