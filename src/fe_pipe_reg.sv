`default_nettype none

// Fetch-execute pipeline register
module fe_pipe_reg (
    input  logic clk,
    input  logic rst,
    input  logic write_enable_FE,
    input  logic clear_FE,

    input  logic [11:0] instruction_FE_in,
    input  logic [9:0] pc_plus_1_FE_in,

    output logic [11:0] instruction_FE_out,
    output logic [9:0] pc_plus_1_FE_out
);

    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter [INSTRUCTION_WIDTH - 1:0] NOP = 12'b101100010001; // B11 // NOP instruction B11
    /////////////////////////////////////////

    logic [3:0] opcode_FE_in, opcode_FE_out;
    assign opcode_FE_in = instruction_FE_in[11:8];
    assign opcode_FE_out = instruction_FE_out[11:8];
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            instruction_FE_out <= NOP;
            pc_plus_1_FE_out <= '0;
        end
        
        else begin 
            if (clear_FE) begin
                instruction_FE_out <= NOP;
                pc_plus_1_FE_out <= '0;
            end else if (write_enable_FE) begin
                instruction_FE_out <= instruction_FE_in;
                pc_plus_1_FE_out <= pc_plus_1_FE_in;
            end
            
        end
        
        
    end

endmodule

`default_nettype wire