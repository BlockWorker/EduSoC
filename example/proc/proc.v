//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: proc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - main core module
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module proc #(
    parameter CORE_ID = 32'd0
) (
    input CLK,
    input RES,
    input [31:0] INSTR_READ,
    input INSTR_VALID,
    input [31:0] DATA_READ,
    input DATA_VALID,
    input IRQ,
    input [4:0] IRQ_ID,
    output [31:0] INSTR_ADR,
    output INSTR_REQ,
    output [31:0] DATA_WRITE,
    output [31:0] DATA_ADR,
    output DATA_REQ,
    output DATA_WRITE_ENABLE,
    output [3:0] DATA_BE,
    output IRQ_ACK,
    output [4:0] IRQ_ACK_ID
);

  wire [31:0] INSTR;
  wire INSTR_LOAD;
  wire PC_EN;
  wire PC_MODE;
  wire [4:0] REG_A_Q0;
  wire [4:0] REG_A_Q1;
  wire [4:0] REG_A_D;
  wire REG_WRITE;
  wire [31:0] REG_Q0;
  wire [31:0] REG_Q1;
  wire [2:0] IMM_MODE;
  wire [31:0] IMM;
  wire A_SELECT;
  wire [31:0] OPERAND_A;
  wire B_SELECT;
  wire [31:0] OPERAND_B;
  wire [1:0] D_SELECT;
  wire [31:0] WRITEBACK_DATA;
  wire PC_SELECT;
  wire [31:0] PC_INPUT;
  wire [6:0] ALU_S;
  wire [31:0] ALU_OUT;
  wire [31:0] MUL_OUT;
  wire [31:0] MUL_BUFFER_OUT;
  wire CMP;
  wire [31:0] PC_OUT;
  wire [31:0] ISR_PC_WRITE;
  wire ENTER_ISR;
  wire [31:0] CSR_OUT;
  wire DATA_REQ_INT;
  wire DATA_VALID_INT;
  wire DATA_WRITE_ENABLE_INT;
  wire [31:0] DATA_READ_INT;

  //instruction always loaded from PC address
  assign INSTR_ADR = PC_OUT;

  //register set
  regset regset (
      .D(WRITEBACK_DATA),
      .A_D(REG_A_D),
      .A_Q0(REG_A_Q0),
      .A_Q1(REG_A_Q1),
      .write_enable(REG_WRITE),
      .RES(RES),
      .CLK(CLK),
      .Q0(REG_Q0),
      .Q1(REG_Q1)
  );

  //CSR set
  csrset #(
      .CORE_ID(CORE_ID)
  ) csrset (
      .CLK(CLK),
      .RES(RES),
      .INSTR_DONE(PC_EN && ~ENTER_ISR),
      .ADR(INSTR[31:20]),
      .OUT(CSR_OUT)
  );

  //program counter
  pc pc (
      .D(PC_INPUT),
      .MODE(PC_MODE),
      .ENABLE(PC_EN),
      .RES(RES),
      .CLK(CLK),
      .PC_OUT(PC_OUT)
  );

  //ALU
  alu alu (
      .S(ALU_S),
      .A(OPERAND_A),
      .B(OPERAND_B),
      .CMP(CMP),
      .Q(ALU_OUT),
      .MUL_OUT(MUL_OUT)
  );

  //immediate generator
  immgen immgen (
      .INSTR(INSTR),
      .MODE (IMM_MODE),
      .IMM  (IMM)
  );

  //memory access manager
  memaccess_manager mamgr (
      .CLK(CLK),
      .RES(RES),
      .TYPE(INSTR[14:12]),
      .DATA_REQ(DATA_REQ_INT),
      .DATA_WRITE_ENABLE(DATA_WRITE_ENABLE_INT),
      .DATA_VALID(DATA_VALID_INT),
      .DATA_ADR(ALU_OUT),
      .DATA_READ(DATA_READ_INT),
      .DATA_WRITE(REG_Q1),
      .MEM_REQ(DATA_REQ),
      .MEM_WRITE_ENABLE(DATA_WRITE_ENABLE),
      .MEM_VALID(DATA_VALID),
      .MEM_ADR(DATA_ADR),
      .MEM_READ(DATA_READ),
      .MEM_WRITE(DATA_WRITE),
      .MEM_BE(DATA_BE)
  );

  //ISR manager
  isr_manager isr_manager (
      .CLK(CLK),
      .RES(RES),
      .PC_READ(PC_OUT),
      .PC_WRITE(ISR_PC_WRITE),
      .IRQ_ID(IRQ_ID),
      .IRQ_ACK(IRQ_ACK),
      .IRQ_ACK_ID(IRQ_ACK_ID),
      .ENTER_ISR(ENTER_ISR)
  );

  //control logic
  ctrl ctrl (
      .CLK(CLK),
      .RES(RES),
      .INSTR(INSTR),
      .INSTR_VALID(INSTR_VALID),
      .CMP(CMP),
      .DATA_VALID(DATA_VALID_INT),
      .IRQ(IRQ),
      .INSTR_REQ(INSTR_REQ),
      .DATA_REQ(DATA_REQ_INT),
      .DATA_WRITE_ENABLE(DATA_WRITE_ENABLE_INT),
      .INSTR_LOAD(INSTR_LOAD),
      .PC_EN(PC_EN),
      .PC_MODE(PC_MODE),
      .A_SEL(A_SELECT),
      .B_SEL(B_SELECT),
      .D_SEL(D_SELECT),
      .PC_SEL(PC_SELECT),
      .ENTER_ISR(ENTER_ISR),
      .IMM_MODE(IMM_MODE),
      .REG_A_Q0(REG_A_Q0),
      .REG_A_Q1(REG_A_Q1),
      .REG_A_D(REG_A_D),
      .REG_WRITE(REG_WRITE),
      .ALU_S(ALU_S)
  );

  //instruction register
  REG_DRE_32 instr_reg (
      .D(INSTR_READ),
      .Q(INSTR),
      .CLK(CLK),
      .RES(RES),
      .ENABLE(INSTR_LOAD)
  );

  //multiply buffer
  REG_DR_32 mul_buffer (
      .D  (MUL_OUT),
      .Q  (MUL_BUFFER_OUT),
      .CLK(CLK),
      .RES(RES)
  );

  //operand A multiplexer
  MUX_2x1_32 op_a_mux (
      .I0(REG_Q0),
      .I1(PC_OUT),
      .S (A_SELECT),
      .Y (OPERAND_A)
  );

  //operand B multiplexer
  MUX_2x1_32 op_b_mux (
      .I0(REG_Q1),
      .I1(IMM),
      .S (B_SELECT),
      .Y (OPERAND_B)
  );

  //writeback data multiplexer
  MUX_4x1_32 writeback_mux (
      .I0(ALU_OUT),
      .I1(MUL_BUFFER_OUT),
      .I2(DATA_READ_INT),
      .I3(CSR_OUT),
      .S (D_SELECT),
      .Y (WRITEBACK_DATA)
  );

  //program counter load multiplexer
  MUX_2x1_32 pc_mux (
      .I0(ALU_OUT),
      .I1(ISR_PC_WRITE),
      .S (PC_SELECT),
      .Y (PC_INPUT)
  );

endmodule
