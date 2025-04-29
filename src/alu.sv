`default_nettype none
// ALU
module alu (
    input  logic signed [11:0] a, b,
    input  logic [3:0] opcode,
    output logic [11:0] result,
    output logic zero_flag, positive_flag
);

    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter INSTRUCTION_WIDTH = 12; // Instruction width in bits
    parameter [INSTRUCTION_WIDTH - 1:0] NOP = 12'b101100010001; // B11 // NOP instruction B11

    parameter OPCODE_WIDTH = 4; // Opcode width in bits
    parameter [OPCODE_WIDTH - 1:0] HALT   = 4'b0000; // HALT instruction
    parameter [OPCODE_WIDTH - 1:0] LOAD   = 4'b0001; // LOAD instruction
    parameter [OPCODE_WIDTH - 1:0] STOREL = 4'b0110; // STORE lower instruction
    parameter [OPCODE_WIDTH - 1:0] STOREU = 4'b0111; // STORE upper instruction
    parameter [OPCODE_WIDTH - 1:0] ADD    = 4'b1000; // ADD instruction
    parameter [OPCODE_WIDTH - 1:0] SUB    = 4'b1001; // SUB instruction
    parameter [OPCODE_WIDTH - 1:0] AND    = 4'b1010; // AND instruction
    parameter [OPCODE_WIDTH - 1:0] OR     = 4'b1011; // OR instruction
    parameter [OPCODE_WIDTH - 1:0] XOR    = 4'b1100; // XOR instruction
    parameter [OPCODE_WIDTH - 1:0] SL     = 4'b1101; // Shift left instruction
    parameter [OPCODE_WIDTH - 1:0] SRL    = 4'b1110; // Shift right logical instruction
    parameter [OPCODE_WIDTH - 1:0] SRA    = 4'b1111; // Shift right arithmetic instruction
    parameter [OPCODE_WIDTH - 1:0] NOT    = 4'b0101; // NOT instruction
    parameter [OPCODE_WIDTH - 1:0] LI     = 4'b0100; // Load immediate instruction
    parameter [OPCODE_WIDTH - 1:0] JUMP   = 4'b0010; // JUMP instruction
    parameter [OPCODE_WIDTH - 1:0] BRANCH = 4'b0011; // BRANCH instruction (z or p flag)

    /////////////////////////////////////////


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