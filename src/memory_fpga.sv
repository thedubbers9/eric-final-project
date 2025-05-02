module memory_fpga (
    input  wire        clk,
    input  wire        rst,
    input  wire        read_write,    // 1 = read, 0 = write
    input  wire        write_commit,   
    input  wire [9:0]  addr_data,    
    output reg  [11:0] mem_result     // data out
);

    reg [11:0] memory_array [0:1023];
    reg [9:0]  write_addr;

    always @(posedge clk) begin
        if (rst) begin
            write_addr <= 10'b0;
        end else if (~read_write && ~write_commit) begin
            write_addr <= addr_data;
        end else if (~read_write && write_commit) begin
            if (addr_data[6]) begin
                memory_array[write_addr][11:6] <= addr_data[5:0];
            end else begin
                memory_array[write_addr][5:0] <= addr_data[5:0];
            end
        end
    end

    // Read path: for the FPGA this needs to be a sequential read.
    always @(posedge clk) begin
        if (read_write)
            mem_result <= memory_array[addr_data];
        else
            mem_result <= 12'b0;
    end

endmodule
