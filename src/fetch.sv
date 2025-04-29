`default_nettype none

// Instruction Fetch Unit
module fetch (
    input  logic clk,
    input  logic rst,
    input  logic pc_enable,
    input  logic [9:0] next_pc,
    input  logic [11:0] instruction_from_mem,
    input logic take_branch,

    output logic [9:0] pc_out, pc_plus_1_out
);
     
    assign pc_plus_1_out = pc_out + 1'b1;
    
    logic [9:0] next_pc_internal;

    assign next_pc_internal = take_branch ? next_pc : (pc_enable ? pc_plus_1_out : pc_out); // Update PC based on branch condition

    // FF for PC
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_out <= '0;
        end else  begin
            pc_out <= next_pc_internal;
        end
    end

endmodule

`default_nettype wire