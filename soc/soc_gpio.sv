`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 29.06.2023 12:10:22
// Design Name: 
// Module Name: soc_gpio
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: GPIO (general purpose input/output) controller. Supports up to 16 ports of 32 pins each.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


import registers::*;

  typedef enum logic [3:0] {
    PORT = 0,
    LATCH = 1,
    DIR = 2,
    CNR = 3,
    CNF = 4,
    CN_STATE = 5,
    INT_STATUS = 'hF
  } gpio_conf_t;

module soc_gpio #(
    parameter BUS_LATENCY = 1,
    parameter PORT_COUNT  = 1   //how many GPIO ports are created (32 pins each)
) (
    input clk,
    input res,

    input  [(32*PORT_COUNT)-1:0] gpio_in,
    output [(32*PORT_COUNT)-1:0] gpio_out,
    output [(32*PORT_COUNT)-1:0] gpio_drive,

    output reg interrupt_trigger,

    SoC_MemBus.Slave mem_bus
);

  initial
    assert (PORT_COUNT <= 16)
    else $error("GPIO module only supports up to 16 ports.");

  wire [31:0] addr;
  wire [3:0] register_index = addr[11:8];  //index of selected port
  gpio_conf_t register_addr;  //local register address within selected port
  reg_access_t register_type;  //register access type
  reg [31:0] register_out_value;  //output value of selected register (for read)
  reg [31:0] register_unchanged_value;  //"unchanged" value of selected register (for write)
  wire [31:0] register_write;
  wire write_enabled;

  reg [31:0] interrupt_status;

  wire [31:0] ports[PORT_COUNT-1:0];
  reg [31:0] port_latches[PORT_COUNT-1:0];
  reg [31:0] port_directions[PORT_COUNT-1:0];
  reg [31:0] port_cn_rising[PORT_COUNT-1:0];
  reg [31:0] port_cn_falling[PORT_COUNT-1:0];
  reg [31:0] port_cn_states[PORT_COUNT-1:0];

  reg [31:0] port_previous[PORT_COUNT-1:0];
  wire [31:0] port_changes[PORT_COUNT-1:0];
  wire [31:0] port_rising[PORT_COUNT-1:0];
  wire [31:0] port_falling[PORT_COUNT-1:0];

  assign register_type = reg_access_t'(addr[3:2]);
  assign register_addr = gpio_conf_t'(addr[7:4]);

  //memory bus controller
  soc_peripheral_controller #(
      .LATENCY(BUS_LATENCY)
  ) per_ctl (
      .clk(clk),
      .res(res),
      .bus(mem_bus),
      .data_out(register_out_value),
      .unchanged_value(register_unchanged_value),
      .addr_out(addr),
      .write_data(register_write),
      .we(write_enabled)
  );

  //GPIO connections
  generate
    genvar i, j;

    for (i = 0; i < PORT_COUNT; i++) begin
      for (j = 0; j < 32; j++) begin  //port input assignment for reading
        assign ports[i][j] = port_directions[i][j] ? port_latches[i][j] : gpio_in[32*i+j];
      end

      assign gpio_out[(32*i+31):(32*i)] = port_latches[i] & port_directions[i]; //port output assignment
      assign gpio_drive[(32*i+31):(32*i)] = port_directions[i];  //port driver enables

      assign port_changes[i] = (ports[i] ^ port_previous[i]) & ~port_directions[i]; //all changed inputs
      assign port_rising[i] = port_changes[i] & ports[i] & port_cn_rising[i];  //rising edges for CN
      assign port_falling[i] = port_changes[i] & ~ports[i] & port_cn_falling[i]; //falling edges for CN
    end
  endgenerate

  //register read value assignment
  always @(*) begin
    register_unchanged_value = 32'b0;
    register_out_value = 32'b0;

    if (register_type == MAIN) begin
      if (register_addr == INT_STATUS) begin //int status is a global register, don't care about port index
        register_unchanged_value = interrupt_status;
        register_out_value = interrupt_status;
      end else if (register_index < PORT_COUNT) begin
        case (register_addr)
          PORT: begin
            register_unchanged_value = port_latches[register_index];
            register_out_value = ports[register_index];
          end
          LATCH: begin
            register_unchanged_value = port_latches[register_index];
            register_out_value = port_latches[register_index];
          end
          DIR: begin
            register_unchanged_value = port_directions[register_index];
            register_out_value = port_directions[register_index];
          end
          CNR: begin
            register_unchanged_value = port_cn_rising[register_index];
            register_out_value = port_cn_rising[register_index];
          end
          CNF: begin
            register_unchanged_value = port_cn_falling[register_index];
            register_out_value = port_cn_falling[register_index];
          end
          CN_STATE: begin
            register_unchanged_value = port_cn_states[register_index];
            register_out_value = port_cn_states[register_index];
          end
          default:  /*Do nothing in case of invalid value*/;
        endcase
      end
    end
  end

  //register writing and change notification handling
  always @(posedge clk) begin
    interrupt_trigger <= 0; //always reset the interrupt trigger - only high for one clock cycle per event

    if (res) begin
      interrupt_status <= 32'b0;

      for (int i = 0; i < PORT_COUNT; i++) begin
        port_latches[i] <= 32'b0;
        port_directions[i] <= 32'b0;
        port_cn_rising[i] <= 32'b0;
        port_cn_falling[i] <= 32'b0;
        port_cn_states[i] <= 32'b0;
        port_previous[i] <= ports[i];
      end
    end else begin
      if (write_enabled) begin
        if (register_addr == INT_STATUS) begin //int status is a global register, don't care about port index, clear only
          if (register_type == MAIN) interrupt_status <= interrupt_status & register_write;
          else if (register_type == CLR || register_type == INV)
            interrupt_status <= interrupt_status & ~register_write;
        end else if (register_index < PORT_COUNT) begin
          case (register_addr)
            PORT | LATCH: begin  //write to port equals write to latch
              port_latches[register_index] <=
                  writeval(port_latches[register_index], register_write, register_type);
            end
            DIR: begin
              port_directions[register_index] <=
                  writeval(port_directions[register_index], register_write, register_type);
            end
            CNR: begin
              port_cn_rising[register_index] <=
                  writeval(port_cn_rising[register_index], register_write, register_type);
            end
            CNF: begin
              port_cn_falling[register_index] <=
                  writeval(port_cn_falling[register_index], register_write, register_type);
            end
            CN_STATE: begin
              port_cn_states[register_index] <= clearonly(port_cn_states[register_index], register_write, register_type);
            end
            default:  /* Do nothing in case of invalid address. */;
          endcase
        end
      end

      for (int i = 0; i < PORT_COUNT; i++) begin
        if (port_rising[i] != 32'b0 || port_falling[i] != 32'b0) begin  //register any new changes
          for (int j = 0; j < 32; j++) begin
            if (port_rising[i][j] || port_falling[i][j]) port_cn_states[i][j] <= 1;
          end
          interrupt_status[i] <= 1;
          interrupt_trigger   <= 1;
        end

        port_previous[i] <= ports[i];
      end
    end
  end

endmodule
