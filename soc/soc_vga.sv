`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 05.07.2023 12:15:38
// Design Name: 
// Module Name: soc_vga
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: VGA controller, designed with the Digilent PmodVGA board in mind.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_vga #(
    parameter FRAME_WIDTH  = 640,
    parameter FRAME_HEIGHT = 480,
    parameter FRAME_OFFSET = 0,    //first line in frame that is actually active

    parameter H_FP  = 16,  //H front porch width (pixels)
    parameter H_PW  = 96,  //H sync pulse width (pixels)
    parameter H_MAX = 800, //H total period (pixels)

    parameter V_FP  = 10,  //V front porch width (lines)
    parameter V_PW  = 2,   //V sync pulse width (lines)
    parameter V_MAX = 525, //V total period (lines)

    parameter FIRST_COL  = 144,  //first pixel/column in frame
    parameter LAST_COL   = 784,  //last pixel/column in frame
    parameter FIRST_LINE = 35,   //first line in frame
    parameter LAST_LINE  = 515,  //last line in frame

    parameter H_POL = 0,  //polarity (active state) of H sync pulse
    parameter V_POL = 0   //polarity (active state) of V sync pulse
) (
    input clk,
    input res,

    output reg vga_hsync,
    output reg vga_vsync,
    output [3:0] vga_r,
    output [3:0] vga_g,
    output [3:0] vga_b,

    output reg [31:0] pixel_address,
    input [7:0] pixel_data
);

  wire active;
  wire hsync, vsync;
  reg [11:0] h_count;
  reg [11:0] v_count;

  assign active = (h_count < FRAME_WIDTH && v_count < (FRAME_HEIGHT - FRAME_OFFSET) && v_count >= FRAME_OFFSET); //in active display area?
  assign hsync = (h_count >= (H_FP + FRAME_WIDTH - 1) && h_count < (H_FP + FRAME_WIDTH + H_PW - 1)) ^ ~H_POL; //horizontal sync pulse
  assign vsync = (v_count >= (V_FP + FRAME_HEIGHT - 1) && v_count < (V_FP + FRAME_HEIGHT + V_PW - 1)) ^ ~V_POL; //vertical sync pulse

  assign vga_r = active ? {pixel_data[7:5], 1'b0} : 4'b0;
  assign vga_g = active ? {pixel_data[4:2], 1'b0} : 4'b0;
  assign vga_b = active ? {pixel_data[1:0], 2'b0} : 4'b0;

  initial begin
    h_count <= 12'b0;
    v_count <= 12'b0;
    vga_hsync <= ~H_POL;
    vga_vsync <= ~V_POL;
    pixel_address <= 32'b0;
  end

  always @(posedge clk) begin
    if (res) begin
      h_count <= 12'b0;
      v_count <= 12'b0;
      vga_hsync <= ~H_POL;
      vga_vsync <= ~V_POL;
      pixel_address <= 32'b0;
    end else begin
      vga_hsync <= hsync;  //transfer hsync and vsync signals to outputs (1 pixel delay)
      vga_vsync <= vsync;

      if (h_count == (H_MAX - 1)) begin  //end of line: go to start of next line
        h_count <= 12'b0;

        if (v_count == (V_MAX - 1)) begin //end of screen: restart at top of screen, reset pixel address
          v_count <= 12'b0;
          pixel_address <= 32'b0;
        end else begin  //just next line: increment line counter
          v_count <= v_count + 12'd1;
        end
      end else begin  //just next pixel: increment column counter
        h_count <= h_count + 12'd1;
      end

      if (active) begin  //increment pixel address after each pixel in active area
        pixel_address <= pixel_address + 32'd1;
      end
    end
  end

endmodule
