`default_nettype none

// CHATGPT Usage: I asked how to write a debug log. It said to use $fopen and $fwrite. $fopen needs to be in an initial block.

module cpu_hier (
    input  logic clk,
    input  logic rst
);

    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter [INSTRUCTION_WIDTH - 1:0] NOP = 12'b101100010001; // B11 // NOP instruction B11
    /////////////////////////////////////////

    logic [9:0] addr_data;
    logic read_write;
    logic write_commit;
    logic halt;

    my_chip iCPU (
        .io_in(mem_result), // Inputs to your chip
        .io_out({read_write, write_commit, addr_data}), // Outputs from your chip
        .clock(clk),
        .reset(rst) // Important: Reset is ACTIVE-HIGH
    );

    assign halt = read_write & write_commit;


    logic [11:0] mem_result;
    memory iMEM(
        .clk (clk),
        .rst (rst),
        .read_write (read_write),
        .write_commit(write_commit),
        .addr_data (addr_data),
        .mem_result (mem_result), 
        .dump_mem (halt) 
    );

    int mem_trace_file; 
    initial begin
        mem_trace_file = $fopen("prog_trace.txt", "w");
        if (mem_trace_file == 0) begin
            $display("ERROR: Could not open mem trace file.");
            $stop;
        end
    end

    logic [9:0] pc_in_commit; 
    assign pc_in_commit = (iCPU.pc_plus_1_EC_out[9:0] - 1); 

    always_ff @(posedge clk) begin
        if (write_commit & ~read_write) begin
            //$display("T=%0t Write to Mem Addr=%04d Data=%06b\n", $time, addr_data, addr_data);
            //$fwrite(mem_trace_file, "T=%0t Write to Mem [%04d] = %06b\n", $time, iMEM.write_addr, addr_data);
            $fwrite(mem_trace_file, "PC: %04d Instr %03h: Write to Mem [%04d] = %06b\n", pc_in_commit, iCPU.instruction_EC_out, iMEM.write_addr, addr_data[5:0]);
            $fflush(mem_trace_file);
        end
        if (iCPU.i_execute.i_reg_file.reg_write_en & (iCPU.instruction_EC_out != NOP)) begin
            //$display("T=%0t Write to Reg Addr=%04d Data=%06b\n", $time, iCPU.i_execute.i_reg_file.reg_write_addr, iCPU.i_execute.i_reg_file.reg_write_data);
            //$fwrite(mem_trace_file, "T=%0t Write to Reg [%02d] = %012b\n", $time, iCPU.i_execute.i_reg_file.reg_write_addr, iCPU.i_execute.i_reg_file.reg_write_data);
            $fwrite(mem_trace_file, "PC: %04d Instr %03h: Write to Reg [%02d] = %012b\n", pc_in_commit, iCPU.instruction_EC_out, iCPU.i_execute.i_reg_file.reg_write_addr, iCPU.i_execute.i_reg_file.reg_write_data);
            $fflush(mem_trace_file);
        end
    end
    


endmodule

`default_nettype wire