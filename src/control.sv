`default_nettype none
// Control
module control (
    input  logic [9:0] pc,
    input  logic [9:0] mem_address,
    input logic [5:0] mem_write_data, // comes from execute_result in commit stage.
    input logic mem_store, // comes from the execute stage. It is 1 if the instruction in the execute stage is a store instruction.
    input logic mem_load, // comes from the execute stage. It is 1 if the instruction in the execute stage is a load instruction.
    input logic mem_store_commit, // comes from commit stage. It is 1 if the instruction in the commit stage is a store instruction.
    input logic [11:0] instruction_ex_stage,
    input logic [11:0] instruction_c_stage,
    input logic [11:0] mem_result, // directly from memory. 

    output logic pc_enable,
    output logic FE_reg_enable,
    output logic FE_reg_clear,
    output logic EC_reg_enable,
    output logic EC_reg_clear,
    output logic write_commit, // connects to write_commit
    output logic mem_read_write, // connects to read_write
    output logic [9:0] mem_bus_out // connects to addr_data[9:0]

);

    //////// YOSYS DOESN'T SUPPORT PACKAGES ////////
    parameter [11:0] HALT   = 4'b0000; // HALT instruction
    /////////////////////////////////////////

    always_comb begin
        // default values
        pc_enable = 1;
        FE_reg_enable = 0;
        FE_reg_clear = 0;
        EC_reg_enable = 0;
        EC_reg_clear = 0;
        write_commit = 0;
        mem_read_write = 1; // default to read since we don't want to write to memory by default.
        mem_bus_out = '0;


        // logic for memory read/write

        // if there is a store instruction in the commit stage, then this gets priority over all other instructions. 
        if (mem_store_commit) begin
            // configure the mem bus to complete the store instruction.
            mem_read_write = 0;
            mem_bus_out[5:0] = mem_write_data[5:0];

            // if it's a STOREU instruction, then we need to set the 6th bit of the mem_bus_out to 1.
            if (instruction_c_stage[8] == 1) begin
                mem_bus_out[6] = 1;
            end

            write_commit = 1;

            // we need to stall the rest of the pipeline because we can't fetch the next instruction until the store instruction is complete.
            pc_enable = 0;
            FE_reg_enable = 0;
            EC_reg_enable = 0;

            // we stil need to clear the EC pipeline registers (insert a NOP instruction)
            EC_reg_clear = 1;

        end

        // otherwise, if there is a store OR load instruction in the execute stage, then we need to configure the memory bus to handle it.
        else if (mem_store | mem_load) begin 
            // configure the data bus to complete the load operaiton or start the store operation.
            mem_read_write = ~mem_store; 

            mem_bus_out = mem_address;

            write_commit = 0;

            // we need to prevent the next instruction from being fetched because the memory bus is busy.
            pc_enable = 0;
            FE_reg_enable = 0;

            // we still need to clear the FE pipeline registers (insert a NOP instruction)
            FE_reg_clear = 1; 

            // The EC pipeline registers are not cleared because we want to keep the instruction in the execute stage until the memory operation is complete.
            EC_reg_enable = 1;

        end

        // if there is a branch instruction in the execute stage, we need to wait until it resolves before fetching the next instruction.
        else if (instruction_ex_stage[11:9] == 3'b001) begin
            // we need to prevent the next instruction from being fetched because the branch instruction is still resolving.
            pc_enable = 0;
            FE_reg_enable = 0;

            write_commit = 0;

            // we still need to clear the FE pipeline registers (insert a NOP instruction)
            FE_reg_clear = 1; 

            // We need to enable EC pipeline registers to move the instruction to the commit stage.
            EC_reg_enable = 1;

             

        end

        else begin
            // there is no reason to stall the pipeline, so we can continue as normal, fetching the next instruction from memory.
            if (mem_result[11:8] == HALT) begin
                pc_enable = 0;
            end else begin
                pc_enable = 1;
            end
            
            FE_reg_enable = 1;
            EC_reg_enable = 1;

            mem_read_write = 1;
            mem_bus_out = pc;

        end

        // halt condtion is indicated by setting mem_read_write and write_commit both to 1.
        if (instruction_c_stage[11:8] == HALT) begin
            mem_read_write = 1;
            write_commit = 1;
        end

    end

endmodule

`default_nettype wire
