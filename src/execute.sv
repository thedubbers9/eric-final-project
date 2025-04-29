`default_nettype none

// Execute pipeline stage
module execute (
    input  logic [11:0] instruction_FE_out,
    input  logic [9:0] pc_plus_1_FE_out,
    input logic [11:0] mem_result,
    input logic current_p_flag, current_z_flag,

    input logic reg_write_en,
    input logic [3:0] reg_write_addr,
    input logic [11:0] reg_write_data,

    input logic clk,
    input logic rst,

    output logic [11:0] execute_result,
    output logic [3:0] reg_write_addr_EC_in,
    output logic reg_write_en_EC_in,
    output logic [9:0] next_pc,
    output logic take_branch,

    output logic flag_write_enable,
    output logic new_p_flag, new_z_flag,
    output logic mem_store,
    output logic mem_load,
    output logic [9:0] Rs
);


    // internal control signals
    logic jump_op, branch_op, load_imm, mem_store_upper;


    // instantiate decode module
    decode decode_mod (
        .instruction(instruction_FE_out),
        .flag_write_enable(flag_write_enable),
        .jump_op(jump_op),
        .branch_op(branch_op),
        .load_imm(load_imm),
        .reg_write_enable(reg_write_en_EC_in),
        .mem_load(mem_load),
        .mem_store(mem_store), 
        .mem_store_upper(mem_store_upper)
    );


    logic [11:0] data_out_rs, data_out_rd;

    // register file
    register_file i_reg_file(
        .clk(clk),
        .rst(rst),
        .rd_reg_addr(instruction_FE_out[7:4]),
        .rs_reg_addr(instruction_FE_out[3:0]),    
        .reg_write_addr(reg_write_addr),
        .reg_write_data(reg_write_data),  // Data to write
        .reg_write_en(reg_write_en),

        .data_out_rs(data_out_rs),
        .data_out_rd(data_out_rd)
    );


    logic [11:0] alu_input_a, alu_input_b;

    assign alu_input_b = (jump_op | branch_op) ? {{2{pc_plus_1_FE_out[9]}}, pc_plus_1_FE_out} : data_out_rs;

    assign alu_input_a = (branch_op) ? {{5{instruction_FE_out[6]}}, instruction_FE_out[6:0]} : data_out_rd;

    logic [11:0] ALU_out;

    // Instantiate ALU
    alu alu_mod (
        .a(alu_input_a),
        .b(alu_input_b),
        .opcode(instruction_FE_out[11:8]),
        .result(ALU_out),
        .zero_flag(new_z_flag),
        .positive_flag(new_p_flag)
    );


    // Branch and jump logic
    branch_jump bj_logic (
        .pc_plus_1(pc_plus_1_FE_out), 
        .alu_result(ALU_out[9:0]),
        .branch_op(branch_op), 
        .jump_op(jump_op), 
        .prev_zero_flag(current_z_flag), 
        .prev_positive_flag(current_p_flag), 
        .branch_type(instruction_FE_out[7]), // 0 for zero, 1 for positive. this comes from instruction bit 7. 
        .next_pc(next_pc), 
        .take_branch(take_branch)
    );

    logic [11:0] ex_res_1, ex_res_2, mem_store_data;

    assign mem_store_data = (mem_store_upper) ? {6'b0, data_out_rd[11:6]} : {6'b0, data_out_rd[5:0]};

    assign ex_res_1 = (mem_store) ? mem_store_data : ALU_out;

    assign ex_res_2 = (mem_load) ? mem_result : ex_res_1;

    assign execute_result = (load_imm) ? {8'b0, instruction_FE_out[3:0]} : ex_res_2;

    assign reg_write_addr_EC_in = instruction_FE_out[7:4];

    assign Rs = data_out_rs[9:0];


endmodule

`default_nettype wire