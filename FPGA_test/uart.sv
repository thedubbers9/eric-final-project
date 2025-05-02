`default_nettype none


module uart_iface #(
    parameter CLK_FREQ = 25000000,
    parameter BAUD = 115200
) (
    input logic clk,
    input logic [31:0] data,
    input logic send,

    output logic ftdi_rxd,
    input logic ftdi_txd
);

    logic uart_ready, uart_valid;
    logic [3:0] state; // 0 = idle, 1 = wait, 2 = start, 3-6 = chars, 7 = stop
    logic [31:0] buf_latch;

    always_ff @(posedge clk) begin
        if (send && state == 0) begin
            state <= 1;
            buf_latch <= data;
        end

        uart_valid <= 0;

        if (state > 0 && state < 7 && uart_ready && ~uart_valid) begin
            uart_valid <= 1;
            state <= state + 1;
        end

        if (state == 7 && uart_ready && ~uart_valid) begin
            state <= 0;
        end
    end

    logic [7:0] uart_data;
    always_comb begin
        uart_data = 8'h00;
        if (state == 2) uart_data = 8'h55;
        if (state == 3) uart_data = buf_latch[7:0];
        if (state == 4) uart_data = buf_latch[15:8];
        if (state == 5) uart_data = buf_latch[23:16];
        if (state == 6) uart_data = buf_latch[31:24];
        if (state == 7) uart_data = 8'hAA;
    end

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) utx (
        .o_ready(uart_ready),
        .o_out(ftdi_rxd),

        .i_data(uart_data),
        .i_valid(uart_valid),
        .i_clk(clk)
    );


endmodule

// UART Transmitter (8/N/1)
module uart_tx
#(
    parameter CLK_FREQ = 250000,
    parameter BAUD = 9600
)
(
    output wire o_ready,
    output reg o_out,

    input wire [7:0] i_data,
    input wire i_valid,
    input wire i_clk
); 

localparam _CLKS_PER_BIT = CLK_FREQ / BAUD;
localparam [$clog2(_CLKS_PER_BIT * 2):0] CLKS_PER_BIT = _CLKS_PER_BIT[$clog2(_CLKS_PER_BIT * 2):0];

reg[($clog2(_CLKS_PER_BIT) + 1):0] counter;
reg [3:0] state = 0; // 0 = idle, 1 = start bit, 2-9 = data bits, 10 = end bit

reg [7:0] data_send; // Buffer the data in case it changes while sending

assign o_ready = (state == 0);

always_ff @(posedge i_clk) begin
    counter <= 10; // Set counter to default value when idle

    if(state == 0) begin
        // Start transmission
        if(i_valid) begin
            state <= 1;
            data_send <= i_data;

            /* verilator lint_off WIDTH */
            counter <= CLKS_PER_BIT;
            /* verilator lint_on WIDTH */
        end

        // Else stay in idle
    end
    else if (counter == 0) begin
        // End bit
        if(state == 10) begin
            state <= 0;
            `ifdef DEBUG
                $display("TRANSMIT FINISHED");
            `endif
        end

        else begin
            state <= state + 1;
            /* verilator lint_off WIDTH */
            if (state == 10) begin
                counter <= CLKS_PER_BIT - 1;
            end
            else begin
                counter <= CLKS_PER_BIT;
            end
            /* verilator lint_on WIDTH */
        end
    end
    else begin
        counter <= counter - 1;
    end
end

always_comb begin
    if(state == 0) begin
        o_out = 1;
    end
    else if(state == 1) begin
        o_out = 0;
    end
    else if(state == 10) begin
        o_out = 1;
    end
    else begin
        o_out = data_send[state - 2];
    end
end

`ifdef VERILATOR
always @(*)
    assert(o_out || (state != 0));
`endif

endmodule


// UART Reciever (8/N/1)
module uart_rx
#(
    parameter CLK_FREQ = 250000,
    parameter BAUD = 9600
)
(
    output reg [7:0] o_data,
    output reg o_valid,

    input wire i_in,
    input wire i_clk
); 

localparam _CLKS_PER_BIT = CLK_FREQ / BAUD;
localparam [$clog2(_CLKS_PER_BIT * 2):0] CLKS_PER_BIT = _CLKS_PER_BIT[$clog2(_CLKS_PER_BIT * 2):0];
localparam [$clog2(_CLKS_PER_BIT * 2):0] CLKS_PER_1_5_BIT = 3 * CLKS_PER_BIT / 2;

reg[$clog2(_CLKS_PER_BIT * 2):0] counter;
reg [3:0] state = 0; // 0 = idle, 1 = start bit, 2-9 = data bits

always_ff @(posedge i_clk) begin
    o_valid <= 0;
    counter <= 10; // Set counter to default value when idle

    if(state == 0) begin
        // Start bit
        if(i_in == 0) begin
            state <= 1;
            /* verilator lint_off WIDTH */
            counter <= CLKS_PER_1_5_BIT;
            /* verilator lint_on WIDTH */
        end

        // Else stay in idle
    end
    else if (counter == 0) begin
        // End bit
        if(state == 9) begin
            if (i_in == 1) begin
                o_valid <= 1;
                `ifdef DEBUG
                    $display("RECEIVED 0x%H (%B)", o_data, o_data);
                `endif
            end
            else begin
                `ifdef DEBUG
                    $display("INVALID END BIT");
                `endif
            end

            state <= 0;
        end

        // Data bits
        else begin
            state <= state + 1;
            o_data[state - 1] <= i_in;

            /* verilator lint_off WIDTH */
            counter <= CLKS_PER_BIT;
            /* verilator lint_on WIDTH */
        end
    end
    else begin
        counter <= counter - 1;
    end
end

endmodule

