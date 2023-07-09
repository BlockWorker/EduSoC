`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 20.06.2023 14:06:03
// Design Name: 
// Module Name: soc_clock_reset
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Clock and Reset generator. Provides active-high reset, main clock, VGA clock, and configurable UART clock.
//              Requires 100 MHz input clock and optional external reset (active-low).
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module soc_clock_reset #(
        parameter MAIN_PLL_DIVIDER = 16, //Main clock PLL divider (down from 800MHz)
        parameter VGA_PLL_DIVIDER = 32, //VGA clock PLL divider (down from 800MHz)
        parameter UART_PLL_DIVIDER = 31, //UART PLL divider (down from 800MHz) - 31 yields 224x baudrate clock for 115200 baud UART
        parameter UART_POST_DIVIDER = 14 //UART post-divider (multiple of 2, or = 1) - 14 with 224x baudrate above yields 16x baudrate clock for 115200 baud UART (almost no baud rate error)
    ) (
        input in_clk,
        output main_clk,
        output reg uart_clk,
        output vga_clk,
        
        input in_rst_n,
        output out_rst
    );
    
    localparam UART_POST_DIVIDER_INT = UART_POST_DIVIDER / 2;
    
    initial begin
        if (UART_POST_DIVIDER != 1 && UART_POST_DIVIDER % 2 != 0) begin
            $display("Error: UART_POST_DIVIDER must be exactly one, or a multiple of two");
            $finish;
        end
    end
    
    wire clk3, clk4, clk5, clk_fb, lock, main_clk_int, uart_clk_int, uart_clk_undivided, vga_clk_int;
    
    // PLLE2_BASE: Base Phase Locked Loop (PLL)
    // Xilinx HDL Language Template, version 2017.4
    
    PLLE2_BASE #(
      .BANDWIDTH("OPTIMIZED"),  // OPTIMIZED, HIGH, LOW
      .CLKFBOUT_MULT(8),        // Multiply value for all CLKOUT, (2-64)
      .CLKFBOUT_PHASE(0.0),     // Phase offset in degrees of CLKFB, (-360.000-360.000).
      .CLKIN1_PERIOD(10.0),      // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
      // CLKOUT0_DIVIDE - CLKOUT5_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE(MAIN_PLL_DIVIDER),
      .CLKOUT1_DIVIDE(UART_PLL_DIVIDER),
      .CLKOUT2_DIVIDE(VGA_PLL_DIVIDER),
      .CLKOUT3_DIVIDE(1),
      .CLKOUT4_DIVIDE(1),
      .CLKOUT5_DIVIDE(1),
      // CLKOUT0_DUTY_CYCLE - CLKOUT5_DUTY_CYCLE: Duty cycle for each CLKOUT (0.001-0.999).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT5_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .DIVCLK_DIVIDE(1),        // Master division value, (1-56)
      .REF_JITTER1(0.0),        // Reference input jitter in UI, (0.000-0.999).
      .STARTUP_WAIT("TRUE")    // Delay DONE until PLL Locks, ("TRUE"/"FALSE")
    )
    PLLE2_BASE_inst (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(main_clk_int),   // 1-bit output: CLKOUT0
      .CLKOUT1(uart_clk_int),   // 1-bit output: CLKOUT1
      .CLKOUT2(vga_clk_int),   // 1-bit output: CLKOUT2
      .CLKOUT3(clk3),   // 1-bit output: CLKOUT3
      .CLKOUT4(clk4),   // 1-bit output: CLKOUT4
      .CLKOUT5(clk5),   // 1-bit output: CLKOUT5
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clk_fb), // 1-bit output: Feedback clock
      .LOCKED(lock),     // 1-bit output: LOCK
      .CLKIN1(in_clk),     // 1-bit input: Input clock
      // Control Ports: 1-bit (each) input: PLL control ports
      .PWRDWN(1'b0),     // 1-bit input: Power-down
      .RST(1'b0),           // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clk_fb)    // 1-bit input: Feedback clock
    );
    
    // End of PLLE2_BASE_inst instantiation
    
    BUFGCE buf_main_clk (
       .O(main_clk),
       .CE(lock),
       .I(main_clk_int)
    );
    
    BUFGCE buf_uart_clk (
       .O(uart_clk_undivided),
       .CE(lock),
       .I(uart_clk_int)
    );
    
    BUFGCE buf_vga_clk (
       .O(vga_clk),
       .CE(lock),
       .I(vga_clk_int)
    );
    
    if (UART_POST_DIVIDER > 1) begin //post-divider greater than one: post-division is needed
        reg [7:0] uart_clk_counter;
    
        initial begin
            uart_clk <= 1'b0;
            uart_clk_counter <= 8'b0;
        end
        
        always @(posedge uart_clk_undivided) begin
            if (uart_clk_counter == UART_POST_DIVIDER_INT - 1) begin
                uart_clk_counter <= 8'b0;
                uart_clk <= ~uart_clk;
            end else begin
                uart_clk_counter <= uart_clk_counter + 8'd1;
            end
        end
    end else begin //post-divider is equal to one: no post-division, just connect undivided clock to output
        always @(uart_clk_undivided) uart_clk = uart_clk_undivided;
    end
    
    //----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
    proc_sys_reset_0 reset_gen (
      .slowest_sync_clk(main_clk),          // input wire slowest_sync_clk
      .ext_reset_in(in_rst_n),                  // input wire ext_reset_in
      .aux_reset_in(1'b0),                  // input wire aux_reset_in
      .mb_debug_sys_rst(1'b0),          // input wire mb_debug_sys_rst
      .dcm_locked(lock),                      // input wire dcm_locked
      .mb_reset(out_rst)                          // output wire mb_reset
      /*.bus_struct_reset(bus_struct_reset),          // output wire [0 : 0] bus_struct_reset
      .peripheral_reset(peripheral_reset),          // output wire [0 : 0] peripheral_reset
      .interconnect_aresetn(interconnect_aresetn),  // output wire [0 : 0] interconnect_aresetn
      .peripheral_aresetn(peripheral_aresetn)      // output wire [0 : 0] peripheral_aresetn*/
    );
    // INST_TAG_END ------ End INSTANTIATION Template ---------
    
endmodule
