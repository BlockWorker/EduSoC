`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 03.07.2023 18:18:51
// Design Name: 
// Module Name: soc_peripherals
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Peripheral section of EduSoC. Contains all peripherals and their connections, as well as the SoC interrupt mapping.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_peripherals #(
    parameter BUS_LATENCY = 1,
    parameter GPIO_PORT_COUNT = 1,
    parameter PWM_MODULE_COUNT = 1,
    parameter TIMER_COUNT = 1
) (
    input clk,
    input raw_res,

    output core_halt,
    output core_res,
    output soc_res,
    output [15:0] control_flags,

    SoC_MemBus.Slave control_bus,
    SoC_MemBus.Slave gpio_bus,
    SoC_MemBus.Slave timer_bus,
    SoC_MemBus.Slave pwm_bus,

    input [(32*GPIO_PORT_COUNT)-1:0] gpio_in,
    output [(32*GPIO_PORT_COUNT)-1:0] gpio_out,
    output [(32*GPIO_PORT_COUNT)-1:0] gpio_drive,
    output [PWM_MODULE_COUNT-1:0] pwm,

    input [15:0] core_int_triggers,
    SoC_InterruptBus.Generator int_bus
);

  wire [31:0] timer_counts [TIMER_COUNT-1:0];

  wire [31:0] int_triggers;
  wire gpio_int_trigger, timer_int_trigger;

  //SoC control module
  soc_control #(
      .BUS_LATENCY(BUS_LATENCY)
  ) control (
      .clk(clk),
      .raw_res(raw_res),
      .core_halt(core_halt),
      .core_res(core_res),
      .soc_res(soc_res),
      .control_flags(control_flags),
      .int_triggers(int_triggers),
      .mem_bus(control_bus),
      .int_bus(int_bus)
  );

  //GPIO module
  soc_gpio #(
      .BUS_LATENCY(BUS_LATENCY),
      .PORT_COUNT (GPIO_PORT_COUNT)
  ) gpio_i (
      .clk(clk),
      .res(soc_res),
      .gpio_in(gpio_in),
      .gpio_out(gpio_out),
      .gpio_drive(gpio_drive),
      .interrupt_trigger(gpio_int_trigger),
      .mem_bus(gpio_bus)
  );

  //Timer module
  soc_timer #(
      .BUS_LATENCY(BUS_LATENCY),
      .TIMER_COUNT(TIMER_COUNT)
  ) timer (
      .clk(clk),
      .res(soc_res),
      .timer_counts(timer_counts),
      .interrupt_trigger(timer_int_trigger),
      .mem_bus(timer_bus)
  );

  //PWM module
  soc_pwm #(
      .BUS_LATENCY (BUS_LATENCY),
      .MODULE_COUNT(PWM_MODULE_COUNT),
      .TIMER_COUNT (TIMER_COUNT)
  ) pwm_i (
      .clk(clk),
      .res(soc_res),
      .timer_counts(timer_counts),
      .pwm_outputs(pwm),
      .mem_bus(pwm_bus)
  );

  //interrupt mapping
  assign int_triggers = {
    core_int_triggers[15:8],
    8'b0,
    gpio_int_trigger,
    3'b0,
    timer_int_trigger,
    3'b0,
    core_int_triggers[7:0]
  };

endmodule
