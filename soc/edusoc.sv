`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 20.06.2023 13:02:01
// Design Name: 
// Module Name: edusoc
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Central SoC component. Instantiation and connection module for all parts of the SoC.
//              Include this module in a SystemVerilog system configuration to include EduSoC with all features.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`include "soc_defines.sv"


module edusoc(
        input ext_clk,
        input ext_resn,
        
        output vga_hsync,
        output vga_vsync,
        output [3:0] vga_r,
        output [3:0] vga_g,
        output [3:0] vga_b,
        
        input uart_rx,
        output uart_tx,
        
        input [(32*`GPIO_PORT_COUNT)-1:0] gpio_in,
        output [(32*`GPIO_PORT_COUNT)-1:0] gpio_out,
        output [(32*`GPIO_PORT_COUNT)-1:0] gpio_drive,
        output [`PWM_MODULE_COUNT-1:0] pwm,
        
        output core_clk,
        output core_res,
        output [15:0] control_flags,
        
        SoC_MemBus.Slave instr_bus,
        SoC_MemBus.Slave data_bus,
        
        input [15:0] core_int_triggers,
        SoC_InterruptBus.Generator int_bus
    );
    
    reg _ext_clk, _ext_resn;
    wire main_clk, uart_clk;
    wire raw_res, soc_res;
    wire core_halt;
    
    //Simulator clock and reset substitution
    `ifdef XILINX_SIMULATOR
        initial _ext_clk = 0;
        initial _ext_resn = 1;
        always #5 _ext_clk = ~_ext_clk;
    `else
        always @(ext_clk) _ext_clk = ext_clk;
        always @(ext_resn) _ext_resn = ext_resn;
    `endif
    
    //UART master bus
    SoC_MemBus uart_bus();
    
    //Slave buses
    SoC_MemBus bootrom_bus(), control_bus(), gpio_bus(), timer_bus(), pwm_bus(), ram_bus(), framebuffer_bus();
    
    //Clock+reset generator
    soc_clock_reset #(
        .UART_PLL_DIVIDER(`UART_CLK_DIVIDER_PLL),
        .UART_POST_DIVIDER(`UART_CLK_DIVIDER_POST)
    ) clk_rst_gen (
        .in_clk(_ext_clk),
        .main_clk(main_clk),
        .uart_clk(uart_clk),
        .in_rst_n(_ext_resn),
        .out_rst(raw_res)
    );
    
    //UART programming bridge
    soc_uart_bridge uart_bridge (
        .clk(main_clk),
        .uclk(uart_clk),
        .res(raw_res),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .mem_bus(uart_bus.Master)
    );
    
    //SoC peripherals (controller, GPIO, timer, PWM)
    soc_peripherals #(
        .BUS_LATENCY(`MEM_PERIPHERAL_LATENCY),
        .GPIO_PORT_COUNT(`GPIO_PORT_COUNT),
        .PWM_MODULE_COUNT(`PWM_MODULE_COUNT),
        .TIMER_COUNT(`TIMER_COUNT)
    ) peripherals (
        .clk(main_clk),
        .raw_res(raw_res),
        .core_halt(core_halt),
        .core_res(core_res),
        .soc_res(soc_res),
        .control_flags(control_flags),
        .control_bus(control_bus.Slave),
        .gpio_bus(gpio_bus.Slave),
        .timer_bus(timer_bus.Slave),
        .pwm_bus(pwm_bus.Slave),
        .gpio_in(gpio_in),
        .gpio_out(gpio_out),
        .gpio_drive(gpio_drive),
        .pwm(pwm),
        .core_int_triggers(core_int_triggers),
        .int_bus(int_bus)
    );
    
    //Boot ROM
    soc_memory_block #(
        .ADDR_WIDTH(`MEM_BOOTROM_ADDR_WIDTH),
        .MEM_INIT_FILE(`MEM_BOOTROM_INIT),
        .LATENCY(`MEM_BOOTROM_LATENCY)
    ) boot_rom (
        .clk(main_clk),
        .res(soc_res),
        .bus(bootrom_bus.Slave)
    );
    
    //Main RAM
    soc_memory_block #(
        .ADDR_WIDTH(`MEM_RAM_ADDR_WIDTH),
        .MEM_INIT_FILE(`MEM_RAM_INIT),
        .LATENCY(`MEM_RAM_LATENCY)
    ) ram (
        .clk(main_clk),
        .res(soc_res),
        .bus(ram_bus.Slave)
    );
    
    //Video controller with framebuffer
    soc_video_controller #(
        .FB_ADDR_WIDTH(`MEM_FRAMEBUFFER_ADDR_WIDTH),
        .FB_LATENCY(`MEM_FRAMEBUFFER_LATENCY),
        .FB_MEM_SIZE(`VIDEO_FB_MEM_SIZE)
    ) vid (
        .clk(main_clk),
        .res(soc_res),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .fb_mem_bus(framebuffer_bus.Slave)
    );
    
    //Memory bus interconnect
    soc_interconnect #(
        .SLAVE_COUNT(`ADDR_SLAVE_COUNT),
        .SLAVE_START_ADDRESSES({
            `ADDR_FRAMEBUFFER_START,
            `ADDR_RAM_START,
            `ADDR_PWM_START,
            `ADDR_TIMERS_START,
            `ADDR_GPIO_START,
            `ADDR_SOCCON_START,
            `ADDR_BOOTROM_START
        }),
        .SLAVE_END_ADDRESSES({
            `ADDR_FRAMEBUFFER_END,
            `ADDR_RAM_END,
            `ADDR_PWM_END,
            `ADDR_TIMERS_END,
            `ADDR_GPIO_END,
            `ADDR_SOCCON_END,
            `ADDR_BOOTROM_END
        })
    ) interconnect_i (
        .clk(main_clk),
        .res(soc_res),
        .master_buses({
            instr_bus,
            data_bus,
            uart_bus.Slave
        }),
        .slave_buses({
            framebuffer_bus.Master,
            ram_bus.Master,
            pwm_bus.Master,
            timer_bus.Master,
            gpio_bus.Master,
            control_bus.Master,
            bootrom_bus.Master
        })
    );
    
    //Core clock gate for core halting
    BUFGCE core_clk_gate (
       .O(core_clk),
       .CE(~core_halt),
       .I(main_clk)
    );
    
endmodule
