`default_nettype none

// CHATGPT Usage: I asked how to write a debug log. It said to use $fopen and $fwrite. $fopen needs to be in an initial block.

`include "uart.sv"

module cpu_on_fpga (
    output logic [7:0] led,
    input logic [6:0] btn,

    input logic clk_ext,
    
    output logic ftdi_rxd,
    input logic ftdi_txd
);

    logic clk, ext_rst, mem_rst, cpu_rst;

    assign clk = clk_ext;
    assign ext_rst = btn[0]; // Active high reset

    logic [9:0] addr_data;
    logic read_write;
    logic write_commit;
    logic halt;

    // my_chip iCPU (
    //     .io_in(mem_result), // Inputs to your chip
    //     .io_out({read_write, write_commit, addr_data}), // Outputs from your chip
    //     .clock(clk),
    //     .reset(rst) // Important: Reset is ACTIVE-HIGH
    // );

    assign halt = read_write & write_commit;

    logic [9:0] addr_data_to_mem;
    logic read_write_to_mem;
    logic write_commit_to_mem;


    logic [11:0] mem_result;
    memory iMEM(
        .clk (clk),
        .rst (cpu_rst),
        .read_write (read_write_to_mem),
        .write_commit(write_commit_to_mem),
        .addr_data (addr_data_to_mem),
        .mem_result (mem_result), 
        .dump_mem (halt) 
    );




    logic [7:0] count;
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
        .send(count == 8'hFF), // Send every 255 counts
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

    localparam [7:0] START_BYTE = 8'hF5;
    localparam [7:0] STOP_BYTE = 8'hFA;

    // if we see this byte, we output the memory contents to the UART
    localparam [7:0] READ_OUT_MEM_BYTE = 8'hF6;

    // Flop the rx data output
    logic [7:0] byte0, byte1, byte2, byte3;
    logic [1:0] byte_num;
    logic data_valid;
    logic read_out_mem;

    always @ (posedge clk_ext) begin
        if (rx_valid) begin
            if (rx_data == START_BYTE) begin
                byte_num <= 0;
                data_valid <= 0;
            end else if (rx_data == STOP_BYTE) begin
                byte_num <= 0;
                data_valid <= 1;
            end else if (rx_data == READ_OUT_MEM_BYTE) begin
                read_out_mem <= 1;
            end else begin
                case (byte_num)
                    0: byte0 <= rx_data;
                    1: byte1 <= rx_data;
                    2: byte2 <= rx_data;
                    3: byte3 <= rx_data;
                endcase
                byte_num <= byte_num + 1;
                read_out_mem <= 0;
            end
        end
    end


    logic [9:0] address_from_uart;
    logic [11:0] data_from_uart;

    assign address_from_uart = {byte0[4:0], byte1[4:0]};
    assign data_from_uart = {byte2[5:0], byte3[5:0]};

    assign led = data_from_uart[7:0];

    // state machine for reading from memory


    // // state machine for writing to memory
    // logic [5:0] mem_write_state;
    // localparam [5:0] START = 6'b000001; // start here on reset
    // localparam [5:0] CLEAR_MEM = 6'b000010; // clear memory
    // localparam [5:0] SEND_ADDR_L = 6'b000100;
    // localparam [5:0] SEND_DATA_L = 6'b001000;
    // localparam [5:0] SEND_ADDR_U = 6'b010000;
    // localparam [5:0] SEND_DATA_U = 6'b100000;
    // localparam [5:0] WAIT = 6'b000000; // wait for the next data word to be ready

    // // Next state logic 
    // always_ff @(posedge clk_ext) begin
    //     if (ext_rst) begin
    //         mem_write_state <= START;
    //     end else begin
    //         case (mem_write_state)
    //             START: begin
    //                 mem_write_state <= CLEAR_MEM;
    //             end
    //             CLEAR_MEM: begin
    //                 mem_write_state <= WAIT;
    //             end
    //             SEND_ADDR_L: begin
    //                 addr_data <= {byte0, byte1};
    //                 mem_write_state <= SEND_DATA_L;
    //             end
    //             SEND_DATA_L: begin
    //                 addr_data <= {byte2, byte3};
    //                 mem_write_state <= SEND_ADDR_U;
    //             end
    //             SEND_ADDR_U: begin
    //                 addr_data <= {byte0, byte1};
    //                 mem_write_state <= SEND_DATA_U;
    //             end
    //             SEND_DATA_U: begin
    //                 addr_data <= {byte2, byte3};
    //                 mem_write_state <= WAIT;
    //             end
    //             WAIT: begin
    //                 if (data_valid) begin
    //                     mem_write_state <= SEND_ADDR_L;
    //                 end 
    //             end
    //         endcase
    //     end
    // end

    // // Output logic 
    // always_comb begin
    //     // defaults: just from the CPU. 
    //     addr_data_to_mem = addr_data;
    //     read_write_to_mem = read_write;
    //     write_commit_to_mem = write_commit;
        
    //     case (mem_write_state)
    //         START: begin
    //             addr_data_to_mem = addr_data;
    //             read_write_to_mem = read_write;
    //             write_commit_to_mem = write_commit;
    //         end
    //         CLEAR_MEM: begin
    //             addr_data_to_mem = 0;
    //             read_write_to_mem = 1; // Write
    //             write_commit_to_mem = 1; // Commit
    //         end
    //         SEND_ADDR_L: begin
    //             addr_data_to_mem = {byte0, byte1};
    //             read_write_to_mem = 1; // Write
    //             write_commit_to_mem = 1; // Commit
    //         end
    //         SEND_DATA_L: begin
    //             addr_data_to_mem = {byte2, byte3};
    //             read_write_to_mem = 1; // Write
    //             write_commit_to_mem = 1; // Commit
    //         end
    //         SEND_ADDR_U: begin
    //             addr_data_to_mem = {byte0, byte1};
    //             read_write_to_mem = 1; // Write
    //             write_commit_to_mem = 1; // Commit
    //         end
    //         SEND_DATA_U: begin
    //             addr_data_to_mem = {byte2, byte3};
    //             read_write_to_mem = 1; // Write
    //             write_commit_to_mem = 1; // Commit
    //         end 
    //         WAIT: begin 
    //             addr_data_to_mem = addr_data;
    //             read_write_to_mem = read_write;
    //             write_commit_to_mem = write_commit;
    //         end

    //     endcase

    // end 

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


`default_nettype wire