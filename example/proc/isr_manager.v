//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date:
// Design Name: 
// Module Name: isr_manager
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - interrupt manager
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module isr_manager(
    input CLK,
    input RES,
    input [31:0] PC_READ,
    output reg [31:0] PC_WRITE,
    input [4:0] IRQ_ID,
    output reg IRQ_ACK,
    output reg [4:0] IRQ_ACK_ID,
    input ENTER_ISR
    );
    
    reg [31:0] pc_store;
    
    always @(posedge CLK) begin
        if (RES) pc_store <= 32'h1A000000;
        else if (ENTER_ISR) pc_store <= PC_READ;
    end
    
    always @(*) begin
        if (ENTER_ISR) begin
            PC_WRITE = `ISR_BASE_ADDR + (IRQ_ID << 2);
            IRQ_ACK = 1'b1;
            IRQ_ACK_ID = IRQ_ID;
        end else begin
            PC_WRITE = pc_store;
            IRQ_ACK = 1'b0;
            IRQ_ACK_ID = 5'd0;
        end
    end
    
endmodule
