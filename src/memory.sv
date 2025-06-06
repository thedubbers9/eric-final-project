`default_nettype none

// CHATGPT Usage: I asked how to write a debug log. It said to use $fopen and $fwrite. $fopen needs to be in an initial block.

module memory (
    input  logic clk,
    input  logic rst,
    input  logic read_write,
    input  logic write_commit,
    input  logic dump_mem,
    input  logic [9:0] addr_data,
    output logic [11:0] mem_result
);

    // Memory array
    logic [11:0] memory_array [0:1023];

    // Write address. Stored for two cycle write. 
    logic [9:0] write_addr;

    // Write operation
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 1024; i++) begin
                memory_array[i] = '0;
            end
            $readmemh("./tests/add_test_23.hex", memory_array);
        end else if (write_commit & ~read_write) begin
            if (addr_data[6]) begin
                memory_array[write_addr][11:6] <= addr_data[5:0];
            end else begin
                memory_array[write_addr][5:0] <= addr_data[5:0];
            end
        end else if (~write_commit & ~read_write) begin
            write_addr <= addr_data;
        end
    end

    // Read operaton
    always_comb begin
        if (read_write) begin
            mem_result = memory_array[addr_data];
        end else begin
            mem_result = '0;
        end
    end

    // dump mem to file 
    always_ff @(posedge clk) begin
        if (dump_mem) begin
            $writememh("add_test_out33.hex", memory_array);
        end
    end

endmodule


`default_nettype wire