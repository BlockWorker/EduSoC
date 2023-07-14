`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// License: CERN-OHL-W-2.0
// 
// Create Date: 20.06.2023 20:47:36
// Design Name: 
// Module Name: soc_uart
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Simple UART with one-byte receive buffer, with overrun and break detection. Only supports 8N1 mode (8 data bits, no parity, one stop bit).
//              Baud rate is derived from given clock (uclk), specifically [baud rate] = [uclk frequency] / 16.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define UART_RX_STATE_BITS          4
`define UART_RX_WAITING             `UART_RX_STATE_BITS'd0
`define UART_RX_WAITSTART           `UART_RX_STATE_BITS'd1
`define UART_RX_RECEIVE_1           `UART_RX_STATE_BITS'd2 //RECEIVE_2 through RECEIVE_8 states are implied, with indices 3-9
`define UART_RX_WAITSTOP            `UART_RX_STATE_BITS'd10
`define UART_RX_BREAK               `UART_RX_STATE_BITS'd11

`define UART_TX_STATE_BITS          4
`define UART_TX_IDLE                `UART_TX_STATE_BITS'd0
`define UART_TX_START               `UART_TX_STATE_BITS'd1
`define UART_TX_SEND_1              `UART_TX_STATE_BITS'd2 //SEND_2 through SEND_8 states are implied, with indices 3-9
`define UART_TX_STOP                `UART_TX_STATE_BITS'd10

module soc_uart(
    input uclk, //UART clock - should be 16x baud rate
    input res, //synchronous reset, active high
    
    input uart_rx, //UART receive line
    output reg uart_tx, //UART transmit line
    
    output reg rx_full, //asserted high when byte has been received
    output reg [7:0] rx_data, //contains received data, valid if rx_full is high
    
    output tx_empty, //asserted high when transmitter is ready (previous transmission complete)
    input [7:0] tx_data, //data to be transmitted
    input start_tx, //assert high to start tranmission if tx_data
    
    output reg rx_overrun, //asserted high if reception of new byte is detected before previous one is acknowledged
    output reg rx_break, //asserted high if receive break status detected (line low when stop bit expected)
    
    input ack //assert high to acknowledge received byte (or break/overrun status), and reset status
    );
    
    
    reg [3:0] sub_bit_time; //current subdivision of bit time (which sixteenth of the current bit time we are in)
    wire [3:0] next_sub_bit_time = sub_bit_time + 4'd1; //next sub bit time
    
    always @(posedge uclk) begin
        if (res) sub_bit_time <= 4'b0;
        else sub_bit_time <= next_sub_bit_time; //increment sub bit time
    end
    
    initial uart_tx <= 1;
    
    
    // **************************************************************************
    // RECEIVER VARIABLES AND LOGIC
    // **************************************************************************
    
    reg [`UART_RX_STATE_BITS-1:0] rx_state; //receiver state, see defines above
    reg [7:0] rx_buffer; //shift buffer for data reception
    
    reg [3:0] rx_sample_point; //sub-bit time at which data should be sampled for the current transmission
    
    
    always @(posedge uclk) begin
        if (res) begin
            rx_state <= `UART_RX_WAITING;
            rx_buffer <= 8'b0;
            rx_sample_point <= 4'b0;
            rx_full <= 0;
            rx_data <= 8'b0;
            rx_break <= 0;
            rx_overrun <= 0;
        end else begin
            if (ack) begin //acknowledge signal asserted: reset receive flags
                rx_full <= 0;
                rx_overrun <= 0;
                rx_break <= 0;
            end
        
            case (rx_state)
                `UART_RX_WAITING: begin //waiting state: wait for falling edge on RX signal, indicating potential start bit
                    if (~uart_rx) begin
                        rx_sample_point <= sub_bit_time + 4'd8; //sampling should happen at middle of bit time, from initial edge
                        rx_state <= `UART_RX_WAITSTART; //start waiting to check if start bit is valid
                    end
                end
                `UART_RX_WAITSTART: begin //waiting for start bit
                    if (sub_bit_time == rx_sample_point && ~uart_rx) begin //sampling point reached with low line: start receiving
                        rx_state <= `UART_RX_RECEIVE_1;
                    end else if (uart_rx) begin //line goes high at any point: ignore and return to waiting state
                        rx_state <= `UART_RX_WAITING;
                    end
                end
                `UART_RX_WAITSTOP: begin //waiting for stop bit
                    if (sub_bit_time == rx_sample_point) begin //if at sampling point: ensure correct stop bit
                        if (uart_rx) begin //line high: correct stop bit, push value to output buffer and signal that the buffer is full
                            if (rx_full) begin //if we already have a value in the output buffer: signal overrun
                                rx_overrun <= 1;
                            end
                        
                            rx_data <= rx_buffer;
                            rx_full <= 1;
                            rx_break <= 0;
                            rx_state <= `UART_RX_WAITING;
                        end else begin //line low: break condition, signal it
                            rx_full <= 0;
                            rx_overrun <= 0;
                            rx_break <= 1;
                            rx_state <= `UART_RX_BREAK;
                        end
                    end
                end
                `UART_RX_BREAK: begin //in break condition: wait for line to go high again before waiting for next message
                    if (uart_rx) begin
                        rx_state <= `UART_RX_WAITING;
                    end
                end
                default: begin
                    if (rx_state >= `UART_RX_RECEIVE_1 && rx_state < `UART_RX_WAITSTOP) begin //receiving data bit
                        if (sub_bit_time == rx_sample_point) begin //if at sampling point: sample data and continue to next
                            rx_buffer <= {uart_rx, rx_buffer[7:1]};
                            rx_state <= rx_state + `UART_RX_STATE_BITS'd1;
                        end
                    end else begin //invalid state: just reset to waiting
                        rx_state <= `UART_RX_WAITING;
                    end
                end
            endcase
        end
    end
    
    
    // **************************************************************************
    // TRANSMITTER VARIABLES AND LOGIC
    // **************************************************************************
    
    reg [`UART_TX_STATE_BITS-1:0] tx_state; //transmitter state, see defines above
    reg [7:0] tx_buffer; //shift buffer for data transmission
    
    reg [3:0] tx_edge_point; //sub-bit time at which data should be changed for the current transmission
    
    
    always @(posedge uclk) begin
        if (res) begin
            tx_state <= `UART_TX_IDLE;
            tx_buffer <= 8'b0;
            tx_edge_point <= 4'b0;
            uart_tx <= 1;
        end else begin
            case (tx_state)
                `UART_TX_IDLE: begin //idle: wait for send start signal
                    if (start_tx) begin //start transmission: load data to buffer, remember edge point, go to start bit
                        tx_buffer <= tx_data;
                        tx_edge_point <= next_sub_bit_time;
                        tx_state <= `UART_TX_START;
                    end
                end
                `UART_TX_START: begin //send start bit
                    if (sub_bit_time == tx_edge_point) begin //at edge point: pull line low
                        uart_tx <= 0;
                    end else if (next_sub_bit_time == tx_edge_point) begin //before next edge point: go to first send state
                        tx_state <= `UART_TX_SEND_1;
                    end
                end
                `UART_TX_STOP: begin //send stop bit and reset transmitter
                    if (sub_bit_time == tx_edge_point) begin //at edge point: pull line high
                        uart_tx <= 1;
                    end else if (next_sub_bit_time == tx_edge_point) begin //before next edge point: reset and go to idle state
                        tx_state <= `UART_TX_IDLE;
                    end
                end
                default: begin
                    if (tx_state >= `UART_TX_SEND_1 && tx_state < `UART_TX_STOP) begin //sending data bit
                        if (sub_bit_time == tx_edge_point) begin //at edge point: set data bit and shift buffer
                            uart_tx <= tx_buffer[0];
                            tx_buffer <= tx_buffer >> 1;
                        end else if (next_sub_bit_time == tx_edge_point) begin //before next edge point: go to next state
                            tx_state <= tx_state + `UART_TX_STATE_BITS'd1;
                        end
                    end else begin //invalid state: return to idle
                        tx_state <= `UART_TX_IDLE;
                    end
                end
            endcase
        end
    end
    
    assign tx_empty = (tx_state == `UART_TX_IDLE || tx_state == `UART_TX_STOP);
    
endmodule
