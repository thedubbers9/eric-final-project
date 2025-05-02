`default_nettype none

`include "uart.sv"

module ChipInterface (
    output logic [7:0] led,
    input logic [6:0] btn,

    input logic clk_ext,
    
    output logic ftdi_rxd,
    input logic ftdi_txd
);

    logic [7:0] count;
    // Create a counter in the SRC clock domain
    SlowCounter ctr (
        .clk(clk_ext),
        .ctr(count)
    );

    

    // UART TX
    uart_iface #(
        .CLK_FREQ(25000000),
        .BAUD(115200)
    ) iface (
        .clk(clk_ext),
        .data({8'h00, count, 8'h00, count}),
        .send(count%4 == 0),
        .ftdi_rxd, .ftdi_txd()
    );



    // UART RX
    logic [7:0] rx_data;
    logic rx_valid;

    uart_rx #(
        .CLK_FREQ(25000000),
        .BAUD(115200)
    ) iUART_RX(
        .o_data(rx_data),
        .o_valid(rx_valid),

        .i_in(ftdi_txd),
        .i_clk(clk_ext),
    ); 

    localparam [7:0] START_BYTE = 8'h55;
    localparam [7:0] STOP_BYTE = 8'hAA;

    // Flop the rx data output
    logic [7:0] byte0, byte1, byte2, byte3;
    logic [1:0] byte_num;

    always @ (posedge clk_ext) begin
        if (rx_valid) begin
            if (rx_data == START_BYTE) begin
                byte_num <= 0;
            end else if (rx_data == STOP_BYTE) begin
                byte_num <= 0;
            end else begin
                case (byte_num)
                    0: byte0 <= rx_data;
                    1: byte1 <= rx_data;
                    2: byte2 <= rx_data;
                    3: byte3 <= rx_data;
                endcase
                byte_num <= byte_num + 1;
            end
        end
    end


    // Display the error counter on the LEDs
    assign led = byte0;

endmodule

module SlowCounter (
    input logic clk,
    output logic [7:0] ctr
);

    // Create a slow-ish counter
    logic [24:0] tmp;
    always_ff @(posedge clk) begin
        tmp <= tmp + 1;
        if (tmp >= 25000000) begin
            ctr <= ctr + 1;
            tmp <= 0;
        end
    end

endmodule
