`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 22.06.2023 10:38:13
// Design Name: 
// Module Name: soc_memory_block
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Simple block memory component with configurable size (2**ADDR_WIDTH bytes), initialization data, and latency.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_memory_block #(
    parameter ADDR_WIDTH = 12,
    parameter MEM_INIT_FILE = "none",
    parameter LATENCY = 1
) (
    input clk,
    input res,

    SoC_MemBus.Slave bus
);

  localparam WORD_ADDR_WIDTH = ADDR_WIDTH - 2;
  localparam MEM_SIZE = (2 ** WORD_ADDR_WIDTH) * 32;

  wire [WORD_ADDR_WIDTH-1:0] word_addr;
  wire [3:0] we;
  wire [31:0] data_out;

  soc_memory_controller #(
      .ADDR_WIDTH(ADDR_WIDTH),
      .LATENCY(LATENCY)
  ) controller (
      .clk(clk),
      .res(res),
      .bus(bus),
      .mem_data_out(data_out),
      .word_addr_out(word_addr),
      .mem_we(we)
  );

  // xpm_memory_spram: Single Port RAM
  // Xilinx Parameterized Macro, Version 2017.4
  xpm_memory_spram #(

      // Common module parameters
      .MEMORY_SIZE        (MEM_SIZE),         //positive integer
      .MEMORY_PRIMITIVE   ("block"),          //string; "auto", "distributed", "block" or "ultra";
      .MEMORY_INIT_FILE   (MEM_INIT_FILE),    //string; "none" or "<filename>.mem" 
      .MEMORY_INIT_PARAM  (""),               //string;
      .USE_MEM_INIT       (1),                //integer; 0,1
      .WAKEUP_TIME        ("disable_sleep"),  //string; "disable_sleep" or "use_sleep_pin" 
      .MESSAGE_CONTROL    (0),                //integer; 0,1
      .MEMORY_OPTIMIZATION("true"),           //string; "true", "false" 

      // Port A module parameters
      .WRITE_DATA_WIDTH_A(32),  //positive integer
      .READ_DATA_WIDTH_A(32),  //positive integer
      .BYTE_WRITE_WIDTH_A(8),  //integer; 8, 9, or WRITE_DATA_WIDTH_A value
      .ADDR_WIDTH_A(WORD_ADDR_WIDTH),  //positive integer
      .READ_RESET_VALUE_A("0"),  //string
      .ECC_MODE                ("no_ecc"),        //string; "no_ecc", "encode_only", "decode_only" or "both_encode_and_decode" 
      .AUTO_SLEEP_TIME(0),  //Do not Change
      .READ_LATENCY_A(LATENCY + 1),  //non-negative integer
      .WRITE_MODE_A("read_first")  //string; "write_first", "read_first", "no_change" 

  ) xpm_memory_spram_inst (

      // Common module ports
      .sleep(1'b0),

      // Port A module ports
      .clka          (clk),
      .rsta          (res),
      .ena           (1'b1),
      .regcea        (1'b1),
      .wea           (we),
      .addra         (word_addr),
      .dina          (bus.write_data),
      .injectsbiterra(1'b0),
      .injectdbiterra(1'b0),
      .douta         (data_out),
      .sbiterra      (),
      .dbiterra      ()

  );

  // End of xpm_memory_spram instance declaration

endmodule
