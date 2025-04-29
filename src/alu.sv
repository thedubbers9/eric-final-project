`default_nettype none
import common_def::*;
// ALU
module alu (
    input  logic signed [11:0] a, b,
    input  logic [3:0] opcode,
    output logic [11:0] result,
    output logic zero_flag, positive_flag
);


    always_comb begin
        case (opcode)
            4'b1000: result = a + b; // ADD
            4'b1001: result = b - a; // SUB
            4'b1010: result = a & b; // AND
            4'b1011: result = a | b; // OR
            4'b1100: result = a ^ b; // XOR
            4'b1101: result = a << b;    // SL
            4'b1110: result = a >> b;    // SRL
            4'b1111: result = a >>> b;   // SRA
            4'b0101: result = ~b; // NOT
            4'b0011: result = a + b; // branch
            4'b0010: result = a + b; // jump
            default: result = 12'b0;  // NOP
        endcase

        zero_flag = (result == 12'b0);
        positive_flag = (result[11] == 1'b0) & ~zero_flag; // Check if the result is positive (MSB is 0)
    end


endmodule

`default_nettype wire