//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date:
// Design Name: 
// Module Name: pc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - program counter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pc(input [31:0] D,
          input MODE,
          input ENABLE,
          input RES,
          input CLK,
          output [31:0] PC_OUT);

    reg [31:0] counter;

    assign PC_OUT = counter; //output always matches counter

    always @(posedge CLK) begin
        if (RES) counter <= 32'h1A000000; //reset counter to boot ROM address
        else if (ENABLE) begin //do nothing unless enabled
            if (MODE) counter <= D; //jump
            else counter <= counter + 32'd4; //increment
        end
    end

endmodule
