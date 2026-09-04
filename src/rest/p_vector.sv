`timescale 1ns / 1ps

import rsdp_pkg::*;

module p_vector(
    input  logic [Z_BIT_WIDTH-1:0] e_bar_prime,
    input  logic [P_BIT_WIDTH-1:0] chall_1,
    input  logic [P_BIT_WIDTH-1:0] u_prime,
    output logic [P_BIT_WIDTH-1:0] y
    );
logic [P_BIT_WIDTH-1:0] e_prime;
logic [2*P_BIT_WIDTH-1:0] prod,result;

exp_unit exp(
    .data_i (e_bar_prime),
    .data_o (e_prime)
);

assign prod = e_prime * chall_1;
assign result = prod + u_prime;

modulo_unit md(
    .data_i (result),
    .data_o (y)
);

endmodule
