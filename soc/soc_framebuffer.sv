`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 22.06.2023 13:53:04
// Design Name: 
// Module Name: soc_framebuffer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Configurable dual-port block memory module, intended to be used as a VGA framebuffer.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_framebuffer #(
    parameter ADDR_WIDTH_A = 18,
    parameter LATENCY_A = 1,
    parameter ADDR_WIDTH_B = 32,
    parameter MEM_SIZE = 1536000
) (
    input main_clk,
    input vga_clk,
    input res,

    SoC_MemBus.Slave bus_a,

    input [ADDR_WIDTH_B-1:0] word_addr_b,
    output [7:0] read_data_b
);

  localparam WORD_ADDR_WIDTH_A = ADDR_WIDTH_A - 2;

  wire [WORD_ADDR_WIDTH_A-1:0] word_addr_a;
  wire [3:0] we_a;
  wire [31:0] data_out_a;

  soc_memory_controller #(
      .ADDR_WIDTH(ADDR_WIDTH_A),
      .LATENCY(LATENCY_A)
  ) a_controller (
      .clk(main_clk),
      .res(res),
      .bus(bus_a),
      .mem_data_out(data_out_a),
      .word_addr_out(word_addr_a),
      .mem_we(we_a)
  );

  // xpm_memory_tdpram: True Dual Port RAM
  // Xilinx Parameterized Macro, Version 2017.4
  xpm_memory_tdpram #(

      // Common module parameters
      .MEMORY_SIZE(MEM_SIZE),  //positive integer
      .MEMORY_PRIMITIVE("block"),  //string; "auto", "distributed", "block" or "ultra";
      .CLOCKING_MODE("independent_clock"),  //string; "common_clock", "independent_clock" 
      .MEMORY_INIT_FILE("none"),  //string; "none" or "<filename>.mem" 
      .MEMORY_INIT_PARAM(""),  //string;
      .USE_MEM_INIT(0),  //integer; 0,1
      .WAKEUP_TIME("disable_sleep"),  //string; "disable_sleep" or "use_sleep_pin" 
      .MESSAGE_CONTROL(0),  //integer; 0,1
      .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
      .AUTO_SLEEP_TIME(0),  //Do not Change
      .USE_EMBEDDED_CONSTRAINT(0),  //integer: 0,1
      .MEMORY_OPTIMIZATION("true"),  //string; "true", "false" 

      // Port A module parameters
      .WRITE_DATA_WIDTH_A(32),                 //positive integer
      .READ_DATA_WIDTH_A (32),                 //positive integer
      .BYTE_WRITE_WIDTH_A(8),                  //integer; 8, 9, or WRITE_DATA_WIDTH_A value
      .ADDR_WIDTH_A      (WORD_ADDR_WIDTH_A),  //positive integer
      .READ_RESET_VALUE_A("0"),                //string
      .READ_LATENCY_A    (LATENCY_A + 1),      //non-negative integer
      .WRITE_MODE_A      ("read_first"),       //string; "write_first", "read_first", "no_change" 

      // Port B module parameters
      .WRITE_DATA_WIDTH_B(8),            //positive integer
      .READ_DATA_WIDTH_B (8),            //positive integer
      .BYTE_WRITE_WIDTH_B(8),            //integer; 8, 9, or WRITE_DATA_WIDTH_B value
      .ADDR_WIDTH_B      (32),           //positive integer
      .READ_RESET_VALUE_B("0"),          //vector of READ_DATA_WIDTH_B bits
      .READ_LATENCY_B    (1),            //non-negative integer
      .WRITE_MODE_B      ("read_first")  //string; "write_first", "read_first", "no_change" 

  ) xpm_memory_tdpram_inst (

      // Common module ports
      .sleep(1'b0),

      // Port A module ports
      .clka          (main_clk),
      .rsta          (res),
      .ena           (1'b1),
      .regcea        (1'b1),
      .wea           (we_a),
      .addra         (word_addr_a),
      .dina          (bus_a.write_data),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .douta         (data_out_a),
      .sbiterra      (),
      .dbiterra      (),

      // Port B module ports
      .clkb          (vga_clk),
      .rstb          (res),
      .enb           (1'b1),
      .regceb        (1'b1),
      .web           (1'b0),
      .addrb         (word_addr_b),
      .dinb          (8'b0),
      .injectsbiterrb(1'b0),
      .injectdbiterrb(1'b0),
      .doutb         (read_data_b),
      .sbiterrb      (),
      .dbiterrb      ()

  );

  // End of xpm_memory_tdpram instance declaration

endmodule
