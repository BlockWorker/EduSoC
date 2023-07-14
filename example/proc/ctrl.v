//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date:
// Design Name: 
// Module Name: ctrl
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Example for a simple RISC-V core - control logic
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "proc_defines.v"


module ctrl (
    input CLK,
    input RES,
    input [31:0] INSTR,
    input INSTR_VALID,
    input CMP,
    input DATA_VALID,
    input IRQ,
    output reg INSTR_REQ,
    output reg DATA_REQ,
    output reg DATA_WRITE_ENABLE,
    output reg INSTR_LOAD,
    output reg PC_EN,
    output reg PC_MODE,
    output reg A_SEL,
    output reg B_SEL,
    output reg [1:0] D_SEL,
    output reg PC_SEL,
    output reg ENTER_ISR,
    output reg [2:0] IMM_MODE,
    output reg [4:0] REG_A_Q0,
    output reg [4:0] REG_A_Q1,
    output reg [4:0] REG_A_D,
    output reg REG_WRITE,
    output reg [6:0] ALU_S
);

  reg [`CTRL_STATE_BITS-1:0] state;
  reg in_isr;

  wire [6:0] ALU_S_NORMAL = {INSTR[30], INSTR[25], INSTR[14:12], INSTR[6:5]};

  always @(posedge CLK) begin
    if (RES) begin
      state  <= `CTRL_STATE_INIT;
      in_isr <= 1'b0;
    end else begin
      case (state)
        `CTRL_STATE_INIT: state <= `CTRL_STATE_REQ;
        `CTRL_STATE_REQ: if (INSTR_VALID) state <= `CTRL_STATE_LOAD;
        `CTRL_STATE_LOAD: begin
          case (INSTR[6:0])
            `OPCODE_OP: begin
              if (ALU_S_NORMAL == `ALU_MUL) state <= `CTRL_STATE_MUL_BEGIN;
              else state <= `CTRL_STATE_OP;
            end
            `OPCODE_OPIMM: state <= `CTRL_STATE_OPIMM;
            `OPCODE_BRANCH: state <= `CTRL_STATE_BR_CMP;
            `OPCODE_JALR: state <= `CTRL_STATE_JALX_LINK;
            `OPCODE_JAL: state <= `CTRL_STATE_JALX_LINK;
            `OPCODE_AUIPC: state <= `CTRL_STATE_AUIPC;
            `OPCODE_LUI: state <= `CTRL_STATE_LUI;
            `OPCODE_LOAD: state <= `CTRL_STATE_LW_REQ;
            `OPCODE_STORE: state <= `CTRL_STATE_SW;
            `OPCODE_SYS:
            case (INSTR[14:12])
              3'b000: begin
                if (in_isr) state <= `CTRL_STATE_MRET;
                else state <= `CTRL_STATE_CONT;
              end
              3'b010: state <= `CTRL_STATE_CSRR;
            endcase
            default: state <= `CTRL_STATE_CONT;  //unknown operand: continue to next command
          endcase
        end
        `CTRL_STATE_MUL_BEGIN: state <= `CTRL_STATE_MUL_WRITEBACK;
        `CTRL_STATE_BR_CMP: begin
          if (CMP) state <= `CTRL_STATE_BR_JUMP;
          else state <= `CTRL_STATE_CONT;
        end
        `CTRL_STATE_JALX_LINK: begin
          if (INSTR[6:0] == `OPCODE_JAL) state <= `CTRL_STATE_JAL_JUMP;
          else state <= `CTRL_STATE_JALR_JUMP;
        end
        `CTRL_STATE_LW_REQ: if (DATA_VALID) state <= `CTRL_STATE_LW_LOAD;
        `CTRL_STATE_SW: if (DATA_VALID) state <= `CTRL_STATE_CONT;
        `CTRL_STATE_ENTER_ISR: begin
          state  <= `CTRL_STATE_REQ;
          in_isr <= 1'b1;
        end
        `CTRL_STATE_MRET: begin
          if (IRQ) state <= `CTRL_STATE_ENTER_ISR;
          else state <= `CTRL_STATE_REQ;
          in_isr <= 1'b0;
        end
        default: begin //return to start when end of command processing chain is reached or in invalid state
          if (IRQ && ~in_isr) state <= `CTRL_STATE_ENTER_ISR;
          else state <= `CTRL_STATE_REQ;
        end
      endcase
    end
  end

  always @(*) begin
    //Instruction requested only in REQ state
    INSTR_REQ = state == `CTRL_STATE_REQ;
    //Instruction loaded in REQ state if valid
    INSTR_LOAD = state == `CTRL_STATE_REQ && INSTR_VALID;
    //PC enabled in all states except INIT, REQ, LOAD, BR_CMP, JALX_LINK, LW_REQ, SW, and MUL_BEGIN
    PC_EN = state != `CTRL_STATE_INIT && state != `CTRL_STATE_REQ && state != `CTRL_STATE_LOAD && state != `CTRL_STATE_BR_CMP && state != `CTRL_STATE_JALX_LINK && state != `CTRL_STATE_LW_REQ && state != `CTRL_STATE_SW && state != `CTRL_STATE_MUL_BEGIN;
    //PC is loaded in states BR_JUMP, JAL_JUMP, JALR_JUMP, ENTER_ISR, and MRET, otherwise incremented
    PC_MODE = state == `CTRL_STATE_BR_JUMP || state == `CTRL_STATE_JAL_JUMP || state == `CTRL_STATE_JALR_JUMP || state == `CTRL_STATE_ENTER_ISR || state == `CTRL_STATE_MRET;
    //Operand A is PC in states BR_JUMP, JALX_LINK, JAL_JUMP, and AUIPC, otherwise Operand A is Source Register 1
    A_SEL = state == `CTRL_STATE_BR_JUMP || state == `CTRL_STATE_JALX_LINK || state == `CTRL_STATE_JAL_JUMP || state == `CTRL_STATE_AUIPC;
    //Select immediate mode based on command type
    if (state == `CTRL_STATE_OPIMM || state == `CTRL_STATE_JALR_JUMP || state == `CTRL_STATE_LW_REQ)
      IMM_MODE = `IMM_I;
    else if (state == `CTRL_STATE_SW) IMM_MODE = `IMM_S;
    else if (state == `CTRL_STATE_BR_JUMP) IMM_MODE = `IMM_B;
    else if (state == `CTRL_STATE_AUIPC || state == `CTRL_STATE_LUI) IMM_MODE = `IMM_U;
    else if (state == `CTRL_STATE_JAL_JUMP) IMM_MODE = `IMM_J;
    else if (state == `CTRL_STATE_JALX_LINK) IMM_MODE = `IMM_CONST_4;
    else IMM_MODE = `IMM_ZERO;
    //Operand B is immediate value whenever the immediate mode is not zero, otherwise Operand B is Source Register 2
    B_SEL = IMM_MODE != `IMM_ZERO;
    //Source register 1 address is forced to 0 for LUI, otherwise taken from instruction
    REG_A_Q0 = (state == `CTRL_STATE_LUI) ? 5'd0 : INSTR[19:15];
    //Source register 2 and destination register addresses taken from instruction
    REG_A_Q1 = INSTR[24:20];
    REG_A_D = INSTR[11:7];
    //Register content is written in states OP, OPIMM, JALX_LINK, AUIPC, LUI, LW_LOAD, MUL_WRITEBACK, and CSRR
    REG_WRITE = state == `CTRL_STATE_OP || state == `CTRL_STATE_OPIMM || state == `CTRL_STATE_JALX_LINK || state == `CTRL_STATE_AUIPC || state == `CTRL_STATE_LUI || state == `CTRL_STATE_LW_LOAD || state == `CTRL_STATE_MUL_WRITEBACK || state == `CTRL_STATE_CSRR;
    //ALU operation forced to ADD in states BR_JUMP, JALX_LINK, JAL_JUMP, JALR_JUMP, AUIPC, LUI, LW_REQ, and SW, otherwise taken from instruction
    ALU_S = (state == `CTRL_STATE_BR_JUMP || state == `CTRL_STATE_JALX_LINK || state == `CTRL_STATE_JAL_JUMP || state == `CTRL_STATE_JALR_JUMP || state == `CTRL_STATE_AUIPC || state == `CTRL_STATE_LUI || state == `CTRL_STATE_LW_REQ || state == `CTRL_STATE_SW) ? 7'd0 : ALU_S_NORMAL;
    //Data requested only in LW_REQ and SW states
    DATA_REQ = state == `CTRL_STATE_LW_REQ || state == `CTRL_STATE_SW;
    //Data written only in SW state
    DATA_WRITE_ENABLE = state == `CTRL_STATE_SW;
    //Select writeback data source
    case (state)
      `CTRL_STATE_CSRR: D_SEL = 2'd3;
      `CTRL_STATE_LW_LOAD: D_SEL = 2'd2;
      `CTRL_STATE_MUL_WRITEBACK: D_SEL = 2'd1;
      default: D_SEL = 2'd0;
    endcase
    //PC loaded from ISR manager in ENTER_ISR and MRET states, otherwise loaded from ALU
    PC_SEL = state == `CTRL_STATE_ENTER_ISR || state == `CTRL_STATE_MRET;
    //ISR enter signal is set in ENTER_ISR state
    ENTER_ISR = state == `CTRL_STATE_ENTER_ISR;
  end

endmodule
