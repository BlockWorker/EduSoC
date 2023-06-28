`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 06/28/2023 04:22:09 PM
// Design Name: 
// Module Name: soc_interrupt_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Interrupt controller for up to 32 interrupts with static priorities (vector 0 = highest priority).
//              Trigger signals are latching, so the interrupt will keep getting reasserted as long as the trigger is high.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_interrupt_controller(
        input clk,
        input res,
        
        SoC_InterruptBus.Generator int_bus,
        
        input [31:0] enabled_int,
        input [31:0] int_clears,
        input [31:0] int_triggers
    );
    
    reg [31:0] latched_ints = 32'b0; //storage of which interrupts have occurred
    
    always @(latched_ints) begin //interrupt bus output is combinatorial: essentially a priority encoder on latched_ints
        int_bus.irq = 0; //default: no interrupts
        int_bus.irq_id = 5'b0;
        
        for (int i = 0; i < 32; i++) begin
            if (latched_ints[i] && enabled_int[i]) begin //interrupt i latched and enabled: output it, don't check others (lower priority)
                int_bus.irq = 1;
                int_bus.irq_id = i;
                break;
            end
        end
    end
    
    always @(posedge clk) begin
        if (res) begin
            latched_ints <= 32'b0;
        end else begin
            for (int i = 0; i < 32; i++) begin
                if (int_triggers[i]) begin //interrupt trigger/clear: trigger takes priority
                    latched_ints[i] <= 1;
                end else if (int_clears[i]) begin
                    latched_ints[i] <= 0;
                end
            end
        end
    end
    
endmodule
