//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 24.06.2023 20:11:02
// Design Name: 
// Module Name: soc_interfaces
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Interface definitions for the SoC.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

interface SoC_MemBus;
  logic [31:0] addr;
  logic [31:0] read_data;
  logic [31:0] write_data;

  logic write_en;
  logic [3:0] byte_en;

  logic req;
  logic valid;

  modport Master(input read_data, valid, output addr, write_data, write_en, byte_en, req);
  modport Slave(input addr, write_data, write_en, byte_en, req, output read_data, valid);
endinterface

interface SoC_InterruptBus;
  logic irq;
  logic [4:0] irq_id;

  logic irq_ack;
  logic [4:0] irq_ack_id;

  modport Handler(input irq, irq_id, output irq_ack, irq_ack_id);
  modport Generator(input irq_ack, irq_ack_id, output irq, irq_id);
endinterface
