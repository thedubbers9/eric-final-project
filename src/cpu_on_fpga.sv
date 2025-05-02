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
    assign ext_rst = ~btn[0]; // Active high reset. Button is active low.

    logic [9:0] addr_data_from_cpu;
    logic read_write_from_cpu;
    logic write_commit_from_cpu;
    logic halt;

    // my_chip iCPU (
    //     .io_in(mem_result), // Inputs to your chip
    //     .io_out({read_write_from_cpu, write_commit_from_cpu, addr_data_from_cpu}), // Outputs from your chip
    //     .clock(clk),
    //     .reset(rst) // Important: Reset is ACTIVE-HIGH
    // );

    assign halt = read_write_from_cpu & write_commit_from_cpu;

    logic [9:0] addr_data_to_mem;
    logic read_write_to_mem;
    logic write_commit_to_mem;

    always_comb begin // logic to select what is controlling the memory 
        addr_data_to_mem = addr_data_from_cpu;
        read_write_to_mem = read_write_from_cpu;
        write_commit_to_mem = write_commit_from_cpu;

        if (dump_mem_to_uart) begin
            addr_data_to_mem = address_from_read_UART;
            read_write_to_mem = read_write_from_read_UART;
            write_commit_to_mem = write_commit_from_read_UART;
        end else if (load_mem_from_uart) begin
            addr_data_to_mem = address_data_from_write_UART;
            read_write_to_mem = read_write_from_write_UART;
            write_commit_to_mem = write_commit_from_write_UART;
        end
    end

    logic [11:0] mem_result;
    memory_fpga iMEM(
        .clk (clk),
        .rst (cpu_rst),
        .read_write (read_write_to_mem),
        .write_commit(write_commit_to_mem),
        .addr_data (addr_data_to_mem),
        .mem_result (mem_result)
    );

    logic [7:0] count;
    SlowCounter ctr (
        .clk(clk_ext),
        .ctr(count)
    );

    logic uart_tx_done;
    logic send_data_over_UART; // have UART send the data to the host

    // UART TX
    uart_iface #(
        .CLK_FREQ(25000000),
        .BAUD(115200)
    ) iface (
        .clk(clk_ext),
        .data({3'b0, address_from_read_UART[9:5], 3'b0, address_from_read_UART[4:0], 2'b0, mem_result[11:6], 2'b0, mem_result[5:0]}), // 8 bits of data to send}),
        .send(send_data_over_UART), 
        .ftdi_rxd, .ftdi_txd(),
        .uart_tx_done(uart_tx_done) 
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
    localparam [7:0] dump_mem_to_uart_BYTE = 8'hF6;

    // Flop the rx data output
    logic [7:0] byte0, byte1, byte2, byte3;
    logic [1:0] byte_num;
    logic load_mem_from_uart;
    logic dump_mem_to_uart;

    always @ (posedge clk_ext) begin
        if (rx_valid) begin
            if (rx_data == START_BYTE) begin
                byte_num <= 0;
                load_mem_from_uart <= 0;
            end else if (rx_data == STOP_BYTE) begin
                byte_num <= 0;
                load_mem_from_uart <= 1;
            end else if (rx_data == dump_mem_to_uart_BYTE) begin
                load_mem_from_uart <= 0;
                dump_mem_to_uart <= 1;
            end else begin
                case (byte_num)
                    0: byte0 <= rx_data;
                    1: byte1 <= rx_data;
                    2: byte2 <= rx_data;
                    3: byte3 <= rx_data;
                endcase
                byte_num <= byte_num + 1;
                dump_mem_to_uart <= 0;
            end
        end
    end

    // state machine for reading from UART //////////////////////////////////////////
    // logic [1:0] uart_read_state;
    // localparam [1:0] UART_START = 2'b00; // start here on reset/ wait for start byte
    // localparam [1:0] UART_READ = 2'b10; // save uart val
    // localparam [1:0] UART_STOP = 2'b11; // dump memory to UART

    // // next state logic
    // always_ff @(posedge clk_ext) begin
    //     case (uart_read_state)
    //         UART_START: begin
    //             if (rx_valid) begin
    //                 if (rx_data == START_BYTE) begin
    //                     uart_read_state <= UART_READ;
    //                     byte_num <= 0;
    //                     load_mem_from_uart <= 0; // reset the load memory flag.
    //                     dump_mem_to_uart <= 0; // reset the dump memory flag.
    //                 end
    //             end
    //         end
    //         UART_READ: begin
    //             if (rx_valid) begin
    //                 if (rx_data == dump_mem_to_uart_BYTE) begin
    //                     dump_mem_to_uart <= 1; // set the dump memory flag.
    //                     uart_read_state <= UART_STOP; // go to stop state.
    //                 end

    //                 case (byte_num)
    //                     0: byte0 <= rx_data;
    //                     1: byte1 <= rx_data;
    //                     2: byte2 <= rx_data;
    //                     3: byte3 <= rx_data;
    //                 endcase

    //                 if (byte_num == 2'b11) begin // last byte received, go to wait state.
    //                     uart_read_state <= UART_START;
    //                     load_mem_from_uart <= 1; // set the load memory flag.
    //                 end else begin // increment the byte number and stay in read state.
    //                     byte_num <= byte_num + 1;
    //                 end

    //             end 
    //         end

    //         /// UART_STOP is a terminal state, so we don't need to do anything here.
    //         // UART_STOP: begin
    //         //     uart_read_state <= UART_START; // go back to start state.
    //         // end 
    //     endcase
    // end


    logic [9:0] address_from_uart;
    logic [11:0] data_from_uart;

    assign address_from_uart = {byte0[4:0], byte1[4:0]};
    assign data_from_uart = {byte2[5:0], byte3[5:0]};

    // state machine for reading from memory //////////////////////////////////////////
    logic [1:0] mem_read_state;
    localparam [1:0] READ_START = 2'b00; // start here on reset
    localparam [1:0] READ_WAIT = 2'b01; // wait for the next data word to finish being sent
    localparam [1:0] READ = 2'b10; // read from memory
    localparam [1:0] READ_DONE = 2'b11; // done reading from memory

    logic [9:0] address_from_read_UART;
    logic read_write_from_read_UART;
    logic write_commit_from_read_UART;

    

    // next state logic
    always_ff @(posedge clk_ext, posedge ext_rst) begin
        if (ext_rst) begin
            mem_read_state <= READ_START;
            address_from_read_UART <= '0;
        end else begin
            case (mem_read_state)
                READ_START: begin
                    if (dump_mem_to_uart) begin
                        mem_read_state <= READ;
                        address_from_read_UART <= '0;
                    end
                end
                READ_WAIT: begin
                    if (uart_tx_done) begin
                        mem_read_state <= READ;
                    end 
                end
                READ: begin
                    mem_read_state <= READ_WAIT;
                    if (address_from_read_UART == 10'h3FF) begin
                        mem_read_state <= READ_DONE;
                    end
                    address_from_read_UART <= address_from_read_UART + 1;
                end
            endcase
        end
    end

    // moore outputs
    always_comb begin
        send_data_over_UART = 0;
        case (mem_read_state)
            READ_START: begin
                send_data_over_UART = 0;
            end
            READ_WAIT: begin
                send_data_over_UART = 0;
            end
            READ: begin
                send_data_over_UART = 1;
            end
        endcase
    end

    assign read_write_from_read_UART = 1'b1; // Read
    assign write_commit_from_read_UART = 1'b0; 


    /////////////////////////////////////////////////////////////////////////////////////////

    




    // state machine for writing to memory //////////////////////////
    logic [2:0] mem_write_state;
    localparam [2:0] WAIT = 3'b000; // wait for the next data word to be ready from UART.
    localparam [2:0] SEND_ADDR_L = 3'b001;
    localparam [2:0] SEND_DATA_L = 3'b010;
    localparam [2:0] SEND_ADDR_U = 3'b011;
    localparam [2:0] SEND_DATA_U = 3'b100;
    

    // Next state logic 
    always_ff @(posedge clk_ext, posedge ext_rst) begin
        if (ext_rst) begin
            mem_write_state <= WAIT;
        end else begin
            case (mem_write_state)
                SEND_ADDR_L: begin
                    mem_write_state <= SEND_DATA_L;
                end
                SEND_DATA_L: begin
                    mem_write_state <= SEND_ADDR_U;
                end
                SEND_ADDR_U: begin
                    mem_write_state <= SEND_DATA_U;
                end
                SEND_DATA_U: begin
                    mem_write_state <= WAIT;
                end
                WAIT: begin
                    if (load_mem_from_uart) begin
                        mem_write_state <= SEND_ADDR_L;
                    end 
                end
            endcase
        end
    end

    logic [9:0] address_data_from_write_UART;
    logic read_write_from_write_UART;
    logic write_commit_from_write_UART;

    // Output logic 
    always_comb begin
        address_data_from_write_UART = '0;
        read_write_from_write_UART = 1'b1;
        write_commit_from_write_UART = 1'b0;
        
        case (mem_write_state)
            SEND_ADDR_L: begin
                address_data_from_write_UART = address_from_uart;
                read_write_from_write_UART = 0; // Write
                write_commit_from_write_UART = 0; // Commit
            end
            SEND_DATA_L: begin
                address_data_from_write_UART = {4'b0, data_from_uart[5:0]};
                read_write_from_write_UART = 0; // Write
                write_commit_from_write_UART = 1; // Commit
            end
            SEND_ADDR_U: begin
                address_data_from_write_UART = address_from_uart;
                read_write_from_write_UART = 0; // Write
                write_commit_from_write_UART = 0; // Commit
            end
            SEND_DATA_U: begin
                address_data_from_write_UART = {4'b1, data_from_uart[11:6]};
                read_write_from_write_UART = 0; // Write
                write_commit_from_write_UART = 1; // Commit
            end 

        endcase

    end 

    assign led = {data_from_uart[2:0], mem_write_state, mem_read_state};

    //assign led = {7{btn[0]}}; // blink the led when the button is pressed

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