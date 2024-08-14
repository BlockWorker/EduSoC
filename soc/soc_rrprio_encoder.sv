`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 24.06.2023 23:34:21
// Design Name: 
// Module Name: soc_rrprio_encoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Latching priority encoder for interconnect conflict resolution. Selects index 0 with higher priority, else index 1 or 2 in a round-robin way.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_rrprio_encoder (
    input clk,
    input res,
    input [2:0] requests,
    output [2:0] grant
);

  wire conflict = (requests != 3'b0 && requests != 3'b001 && requests != 3'b010 && requests != 3'b100); //whether there is a request conflict on slave i
  reg [2:0] conflict_resolve;  //register for request conflict resolution
  reg next_low;  //which low-priority request should be prioritized next? (round-robin)
  assign grant = conflict ? (conflict_resolve & requests) : requests; //if no conflict, grant request directly, else use conflict resolution register

  always @(posedge clk) begin
    if (res) begin
      conflict_resolve <= 3'b0;
      next_low <= 0;
    end else begin
      if (conflict) begin  //handle conflict
        if ((conflict_resolve & requests) == 3'b0) begin //we never interrupt requests - so wait until previously granted request is no longer present
          if (requests[0])
            conflict_resolve <= 3'b001;  //prioritize external requests (high-priority master)
          else begin  //otherwise: grant low-priority request in round-robin way
            conflict_resolve <= 3'b010 << next_low;
            next_low <= ~next_low;
          end
        end
      end else begin  //no conflict: propagate request to register
        conflict_resolve <= requests;
      end
    end
  end

endmodule
