`default_nettype none

module register_file (
    input  logic clk,
    input  logic rst,
    input  logic [3:0] rd_reg_addr, rs_reg_addr,    // Register Addresses
    input  logic [3:0] reg_write_addr,
    input  logic [11:0] reg_write_data,  // Data to write
    input  logic reg_write_en,

    output logic [11:0] data_out_rs,
    output logic [11:0] data_out_rd
);

    logic [11:0] registers [15:0]; // 16 registers of 12 bits each

    // Read from registers
    always_comb begin
        // make sure to have register file bypass
        if (reg_write_en && reg_write_addr == rs_reg_addr) begin
            data_out_rs = reg_write_data;
        end else begin
            data_out_rs = registers[rs_reg_addr];
        end
        
        if (reg_write_en && reg_write_addr == rd_reg_addr) begin
            data_out_rd = reg_write_data;
        end else begin
            data_out_rd = registers[rd_reg_addr];
        end
        
    end

    // Write to register
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (int i = 0; i < 16; i++) begin
                registers[i] <= 12'b0;
            end
        end else if (reg_write_en) begin
            registers[reg_write_addr] <= reg_write_data;
            //$display("T=%0t Write to Reg[%0d] = %0d\n", $time, reg_write_addr, reg_write_data);
        end
    end

endmodule

`default_nettype wire