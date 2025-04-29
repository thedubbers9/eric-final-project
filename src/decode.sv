`default_nettype none
import common_def::*;

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