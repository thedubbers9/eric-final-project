`default_nettype none

module decode (
    input  logic [11:0] instruction,
    output logic flag_write_enable,
    output logic jump_op,
    output logic branch_op,
    output logic load_imm,
    output logic reg_write_enable,
    output logic mem_load,
    output logic mem_store,
    output logic mem_store_upper
    
);
    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter [11:0] NOP = 12'b101100010001; // B11 // NOP instruction B11

    parameter [3:0] HALT   = 4'b0000; // HALT instruction
    parameter [3:0] LOAD   = 4'b0001; // LOAD instruction
    parameter [3:0] STOREL = 4'b0110; // STORE lower instruction
    parameter [3:0] STOREU = 4'b0111; // STORE upper instruction
    parameter [3:0] ADD    = 4'b1000; // ADD instruction
    parameter [3:0] SUB    = 4'b1001; // SUB instruction
    parameter [3:0] AND    = 4'b1010; // AND instruction
    parameter [3:0] OR     = 4'b1011; // OR instruction
    parameter [3:0] XOR    = 4'b1100; // XOR instruction
    parameter [3:0] SL     = 4'b1101; // Shift left instruction
    parameter [3:0] SRL    = 4'b1110; // Shift right logical instruction
    parameter [3:0] SRA    = 4'b1111; // Shift right arithmetic instruction
    parameter [3:0] NOT    = 4'b0101; // NOT instruction
    parameter [3:0] LI     = 4'b0100; // Load immediate instruction
    parameter [3:0] JUMP   = 4'b0010; // JUMP instruction
    parameter [3:0] BRANCH = 4'b0011; // BRANCH instruction (z or p flag)

    /////////////////////////////////////////
    
    logic [3:0] opcode;
    
    assign opcode = instruction[11:8];

    assign flag_write_enable = (opcode[3] | opcode == NOT) & instruction != NOP;

    assign jump_op = opcode == JUMP;
    assign branch_op = opcode == BRANCH;
    assign load_imm = opcode == LI;
    assign reg_write_enable = (opcode == LOAD) | (opcode == LI) | opcode[3] | (opcode == NOT);
    assign mem_load = (opcode == LOAD);
    assign mem_store = (opcode == STOREL) | (opcode == STOREU);
    assign mem_store_upper = opcode[0];

endmodule

`default_nettype wire