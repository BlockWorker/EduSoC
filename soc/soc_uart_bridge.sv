`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Stuttgart, ITI
// Engineer: Alexander Kharitonov
// 
// Create Date: 21.06.2023 15:51:13
// Design Name: 
// Module Name: soc_uart_bridge
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: UART bridge for external programming/control of the SoC through the UART interface.
//              Implements variable-length writes (in multiples of 4 bytes) to any (4-byte-aligned) memory addresses, with CRC checking for data integrity.
//              See the accompanying programming script for further details on the implemented UART communication protocol.
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`define UBG_STATE_BITS          2
`define UBG_RX_WAIT             `UBG_STATE_BITS'd0
`define UBG_MEM_WAIT            `UBG_STATE_BITS'd1
`define UBG_ERROR               `UBG_STATE_BITS'd2

`define UBG_RXTYPE_BITS         2
`define UBG_RXTYPE_ADR          `UBG_RXTYPE_BITS'd0
`define UBG_RXTYPE_SIZE         `UBG_RXTYPE_BITS'd1
`define UBG_RXTYPE_DATA         `UBG_RXTYPE_BITS'd2
`define UBG_RXTYPE_CRC          `UBG_RXTYPE_BITS'd3

`define UBG_RESPONSE_SUCCESS    8'h59
`define UBG_RESPONSE_BAD_CRC    8'h23
`define UBG_RESPONSE_ERROR      8'he0


module soc_uart_bridge(
        input clk,
        input uclk,
        input res,
        
        input uart_rx,
        output uart_tx,
        
        SoC_MemBus.Master mem_bus
    );
    
    assign mem_bus.byte_en = 4'b1111; //always writing 4 bytes at a time to memory
    
    wire rx_full, rx_overrun, rx_break, tx_empty;
    reg start_tx, uart_ack;
    wire [7:0] rx_data;
    reg [7:0] tx_data;
        
    reg crc_process;
    wire crc_ready, crc_reset;
    wire [31:0] crc;
    
    soc_uart uart (
        .uclk(uclk),
        .res(res),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .rx_full(rx_full),
        .rx_data(rx_data),
        .tx_empty(tx_empty),
        .tx_data(tx_data),
        .start_tx(start_tx),
        .rx_overrun(rx_overrun),
        .rx_break(rx_break),
        .ack(uart_ack)
    );
    
    soc_crc32 crc_engine (
        .clk(clk),
        .res(crc_reset),
        .in_data(rx_data),
        .process_data(crc_process),
        .out_crc(crc),
        .ready(crc_ready)
    );
    
    
    reg [`UBG_STATE_BITS-1:0] state;
    reg [`UBG_RXTYPE_BITS-1:0] rx_type;
    reg [31:0] rx_buffer;
    reg [1:0] rx_byteptr;
    reg [31:0] rx_size_remaining;
    
    wire [31:0] rx_buffer_next = {rx_data, rx_buffer[31:8]}; //receive buffer with last received byte shifted in
    
    assign crc_reset = res || (rx_type == `UBG_RXTYPE_ADR); //always reset CRC engine at the start of a new transaction
    
    always @(posedge clk) begin
        if (res) begin
            mem_bus.addr <= 32'b0;
            mem_bus.write_data <= 32'b0;
            mem_bus.write_en <= 0;
            mem_bus.req <= 0;
            start_tx <= 0;
            uart_ack <= 0;
            tx_data <= 8'b0;
            crc_process <= 0;
            rx_buffer <= 32'b0;
            rx_byteptr <= 2'b0;
            rx_size_remaining <= 32'b0;
            state <= `UBG_RX_WAIT;
            rx_type <= `UBG_RXTYPE_ADR;
        end else begin
            if (~(rx_full || rx_overrun || rx_break)) begin //reset uart_ack if signals successfully acknowledged
                uart_ack <= 0;
            end
            if (~tx_empty) begin //reset start_tx if transmission started
                start_tx <= 0;
            end
            if (~crc_ready) begin //reset crc_process if calculation started
                crc_process <= 0;
            end
            
            case (state)
                `UBG_RX_WAIT: begin //waiting for transmission of given type
                    if (uart_ack) begin
                        //still acknowledging last received byte: do nothing, we're waiting for the UART module
                    end else if (rx_overrun || rx_break) begin //overrun or break condition: go to error case
                        rx_byteptr <= 2'b0;
                        rx_type <= `UBG_RXTYPE_ADR;
                        state <= `UBG_ERROR;
                    end else if (rx_full) begin //received new byte: acknowledge, check further processing
                        uart_ack <= 1;
                        
                        if (rx_type == `UBG_RXTYPE_DATA) crc_process <= 1; //process byte in crc engine if it is part of payload data
                        
                        if (rx_byteptr == 2'd3) begin //last byte in word: read and continue depending on reception type
                            rx_byteptr <= 2'd0; //reset byte pointer
                            case (rx_type)
                                `UBG_RXTYPE_ADR: begin //address: read into address buffer
                                    mem_bus.addr <= rx_buffer_next;
                                    rx_type <= `UBG_RXTYPE_SIZE;
                                end
                                `UBG_RXTYPE_SIZE: begin //size: read into size buffer
                                    rx_size_remaining <= rx_buffer_next;
                                    rx_type <= `UBG_RXTYPE_DATA;
                                end
                                `UBG_RXTYPE_DATA: begin //data: read into data buffer, send to memory
                                    mem_bus.write_data <= rx_buffer_next;
                                    if (rx_size_remaining < 32'd2) begin //last word: receive crc after this
                                        rx_size_remaining <= 32'b0;
                                        rx_type <= `UBG_RXTYPE_CRC;
                                    end else begin //otherwise decrement remaining word count
                                        rx_size_remaining <= rx_size_remaining - 32'd1;
                                    end
                                    mem_bus.write_en <= 1;
                                    mem_bus.req <= 1;
                                    state <= `UBG_MEM_WAIT;
                                end
                                `UBG_RXTYPE_CRC: begin //crc: compare with calculated crc, send back result
                                    if (crc == rx_buffer_next) begin //crc matches: send success byte
                                        tx_data <= `UBG_RESPONSE_SUCCESS;
                                    end else begin //crc doesn't match: send mismatch byte
                                        tx_data <= `UBG_RESPONSE_BAD_CRC;
                                    end
                                    start_tx <= 1;
                                    rx_type <= `UBG_RXTYPE_ADR; //reset to receive next address
                                end
                                default: begin //invalid type: default back to address, error state
                                    rx_type <= `UBG_RXTYPE_ADR;
                                    state <= `UBG_ERROR;
                                end
                            endcase
                        end else begin //not last byte: read into buffer and go to next
                            rx_buffer <= rx_buffer_next;
                            rx_byteptr <= rx_byteptr + 2'd1;
                        end
                    end
                end
                `UBG_MEM_WAIT: begin //waiting for memory transaction
                    if (mem_bus.valid) begin //valid signal received: stop memory request
                        mem_bus.write_en <= 0;
                        mem_bus.req <= 0;
                        
                        if (rx_type == `UBG_RXTYPE_DATA) begin //more data to receive: increment address
                            mem_bus.addr <= mem_bus.addr + 32'd4;
                        end
                        
                        state <= `UBG_RX_WAIT; //receive next
                    end
                end
                `UBG_ERROR: begin //error: continuously transmit error byte
                    if (tx_empty) begin
                        tx_data <= `UBG_RESPONSE_ERROR;
                        start_tx <= 1;
                    end
                end
                default: begin //invalid state: go to error state
                    rx_byteptr <= 2'b0;
                    rx_type <= `UBG_RXTYPE_ADR;
                    state <= `UBG_ERROR;
                end
            endcase
        end
    end
    
endmodule
