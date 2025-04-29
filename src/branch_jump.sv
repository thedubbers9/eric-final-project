`default_nettype none

import common_def::*;
// Branch and jump logic
module branch_jump (
    input  logic [9:0] pc_plus_1, alu_result,
    input  logic branch_op, jump_op, prev_zero_flag, prev_positive_flag, 
    input logic branch_type, // 0 for zero, 1 for positive. this comes from instruction bit 7. 
    output logic [9:0] next_pc, 
    output logic take_branch
);

    // Branch and jump logic
    always_comb begin
        take_branch = 1'b0;
        next_pc = alu_result;
        if (branch_op) begin
            if (branch_type & prev_positive_flag) begin // 
                take_branch = 1'b1;
            end else if (~branch_type & prev_zero_flag) begin 
                take_branch = 1'b1;
            end
        end else if (jump_op) begin 
            take_branch = 1'b1;
        end
    end

endmodule

`default_nettype wire