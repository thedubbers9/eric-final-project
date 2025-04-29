`default_nettype none

// Flags Register
module flags_register (
    input  logic clk,
    input  logic rst,
    input  logic z_in, p_in,
    input logic flag_write_enable,
    output logic z_out, p_out  // Stored flag outputs
);

    // Internal registers for flags
    logic z_reg, p_reg;

    // Sequential logic to update flags on clock edge or reset
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            z_reg <= 1'b0;  // Reset zero flag
            p_reg <= 1'b0;  // Reset parity flag
        end else if (flag_write_enable) begin
            z_reg <= z_in;  // Update zero flag
            p_reg <= p_in;  // Update parity flag
        end
    end

    // Assign output flags from internal registers
    assign z_out = z_reg;
    assign p_out = p_reg;



endmodule

`default_nettype wire