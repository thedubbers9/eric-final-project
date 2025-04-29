`default_nettype none
import common_def::*;
// Top-level CPU module

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock, 
    input logic reset // Important: Reset is ACTIVE-HIGH
);

    logic clk; 
    logic rst; 
    logic [11:0] mem_result;
    logic [9:0] addr_data;
    logic read_write;
    logic write_commit;

    assign clk = clock;
    assign rst = reset;
    assign mem_result = io_in;
    assign io_out = {read_write, write_commit, addr_data};

    // control module
    logic pc_enable;
    logic FE_reg_enable;
    logic FE_reg_clear;
    logic EC_reg_enable;
    logic EC_reg_clear;
    
    control i_control (
        .pc(pc),
        .mem_address(Rs),
        .mem_write_data(execute_result_EC_out[5:0]),
        .mem_store(mem_store),
        .mem_load(mem_load),
        .mem_store_commit(mem_store_EC_out),
        .instruction_ex_stage(instruction_FE_out),
        .instruction_c_stage(instruction_EC_out),
        .mem_result(mem_result),
        .pc_enable(pc_enable),
        .FE_reg_enable(FE_reg_enable),
        .FE_reg_clear(FE_reg_clear),
        .EC_reg_enable(EC_reg_enable),
        .EC_reg_clear(EC_reg_clear),
        .write_commit(write_commit),
        .mem_read_write(read_write),
        .mem_bus_out(addr_data)
    );


    // fetch stage outputs
    logic [9:0] pc, pc_plus_1_out;
    // Fetch stage
    fetch i_fetch (
        .clk(clk),
        .rst(rst),
        .pc_enable(pc_enable),
        .next_pc(next_pc), // for branching
        .instruction_from_mem(mem_result),
        .take_branch(take_branch),
        .pc_out(pc),
        .pc_plus_1_out(pc_plus_1_out)
    );

    // Fetch-execute pipeline register
    // outputs
    logic [11:0] instruction_FE_out;
    logic [9:0] pc_plus_1_FE_out;
    
    fe_pipe_reg i_fe_pipe_reg (
        .clk(clk),
        .rst(rst),
        .write_enable_FE(FE_reg_enable),
        .clear_FE(FE_reg_clear),
        .instruction_FE_in(mem_result),
        .pc_plus_1_FE_in(pc_plus_1_out),
        .instruction_FE_out(instruction_FE_out),
        .pc_plus_1_FE_out(pc_plus_1_FE_out)
    );

    // execute outputs //
    logic [11:0] execute_result;
    logic [3:0] reg_write_addr_EC_in;
    logic reg_write_en_EC_in;
    logic mem_store_EC_in;
    logic [9:0] next_pc;
    logic take_branch;

    logic flag_write_enable;
    logic new_p_flag, new_z_flag;
    logic mem_store;
    logic mem_load;
    logic [9:0] Rs;

    execute i_execute (
        .instruction_FE_out(instruction_FE_out),
        .pc_plus_1_FE_out(pc_plus_1_FE_out),
        .mem_result(mem_result),
        .current_p_flag(current_p_flag),
        .current_z_flag(current_z_flag),
        .reg_write_en(reg_write_en_EC_out),
        .reg_write_addr(reg_write_addr_EC_out),
        .reg_write_data(execute_result_EC_out),
        .clk(clk),
        .rst(rst),
        .execute_result(execute_result),
        .reg_write_addr_EC_in(reg_write_addr_EC_in),
        .reg_write_en_EC_in(reg_write_en_EC_in),
        .next_pc(next_pc),
        .take_branch(take_branch),
        .flag_write_enable(flag_write_enable),
        .new_p_flag(new_p_flag),
        .new_z_flag(new_z_flag),
        .mem_store(mem_store),
        .mem_load(mem_load),
        .Rs(Rs)
    );


    // flags register
    logic current_z_flag, current_p_flag;
    flags_register i_flags_register (
        .clk(clk),
        .rst(rst),
        .z_in(new_z_flag),
        .p_in(new_p_flag),
        .flag_write_enable(flag_write_enable),
        .z_out(current_z_flag),
        .p_out(current_p_flag)
    );

    // Execute-commit pipeline register outputs
    logic mem_store_EC_out;
    logic reg_write_en_EC_out;
    logic [3:0] reg_write_addr_EC_out;
    logic [11:0] execute_result_EC_out;
    logic [11:0] instruction_EC_out;
    logic [9:0] pc_plus_1_EC_out;

    // Execute-commit pipeline register
    ec_pipe_reg i_ec_pipe_reg (
        .clk(clk),
        .rst(rst),
        .write_enable_EC(EC_reg_enable),
        .clear_EC(EC_reg_clear),
        .mem_store_EC_in(mem_store),
        .reg_write_en_EC_in(reg_write_en_EC_in),
        .reg_write_addr_EC_in(reg_write_addr_EC_in),
        .execute_result_EC_in(execute_result),
        .instruction_EC_in(instruction_FE_out),
        .pc_plus_1_EC_in(pc_plus_1_FE_out),
        .mem_store_EC_out(mem_store_EC_out),
        .reg_write_en_EC_out(reg_write_en_EC_out),
        .reg_write_addr_EC_out(reg_write_addr_EC_out),
        .execute_result_EC_out(execute_result_EC_out),
        .instruction_EC_out(instruction_EC_out),
        .pc_plus_1_EC_out(pc_plus_1_EC_out)
    );

    // Commit stage does not have any explicit modules

endmodule

`default_nettype wire