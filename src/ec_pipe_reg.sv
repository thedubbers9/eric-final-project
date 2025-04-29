`default_nettype none

// Execute-commit pipeline register
module ec_pipe_reg (
    input  logic clk,
    input  logic rst,
    input  logic write_enable_EC,
    input  logic clear_EC,

    input  logic mem_store_EC_in,
    input  logic reg_write_en_EC_in,
    input  logic [3:0] reg_write_addr_EC_in,
    input  logic [11:0] execute_result_EC_in,
    input  logic [11:0] instruction_EC_in,
    input  logic [9:0] pc_plus_1_EC_in,

    output  logic mem_store_EC_out,
    output  logic reg_write_en_EC_out,
    output  logic [3:0] reg_write_addr_EC_out,
    output  logic [11:0] execute_result_EC_out,
    output  logic [11:0] instruction_EC_out,
    output  logic [9:0] pc_plus_1_EC_out

);

    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter [INSTRUCTION_WIDTH - 1:0] NOP = 12'b101100010001; // B11 // NOP instruction B11
    /////////////////////////////////////////

    logic [3:0] opcode_EC_in, opcode_EC_out;
    assign opcode_EC_in = instruction_EC_in[11:8];
    assign opcode_EC_out = instruction_EC_out[11:8];

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            mem_store_EC_out <= 1'b0;
            reg_write_en_EC_out <= 1'b0;
            reg_write_addr_EC_out <= 4'b0;
            execute_result_EC_out <= 12'b0;
            instruction_EC_out <= NOP;
            pc_plus_1_EC_out <= '0;
        end else begin 
            if (clear_EC) begin
                mem_store_EC_out <= 1'b0;
                reg_write_en_EC_out <= 1'b0;
                reg_write_addr_EC_out <= 4'b0;
                execute_result_EC_out <= 12'b0;
                instruction_EC_out <= NOP;
                pc_plus_1_EC_out <= '0;
            end else if (write_enable_EC) begin
                mem_store_EC_out <= mem_store_EC_in;
                reg_write_en_EC_out <= reg_write_en_EC_in;
                reg_write_addr_EC_out <= reg_write_addr_EC_in;
                execute_result_EC_out <= execute_result_EC_in;
                instruction_EC_out <= instruction_EC_in;
                pc_plus_1_EC_out <= pc_plus_1_EC_in;
            end
        end
    end


endmodule

`default_nettype wire