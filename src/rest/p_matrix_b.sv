`timescale 1ns / 1ps

import rsdp_pkg::*;

module p_matrix_b(
    input  logic [Z_BIT_WIDTH-1:0] e_bar,
    input  logic [Z_BIT_WIDTH-1:0] e_bar_prime,
    input  logic [P_BIT_WIDTH-1:0] u_prime,
    output logic [P_BIT_WIDTH-1:0] u,
    output logic [Z_BIT_WIDTH-1:0] v_bar
    );
    
logic [2*P_BIT_WIDTH-1:0] prod;
logic [P_BIT_WIDTH-1:0] v;

subz_unit subz(
    .data_i1 (e_bar),
    .data_i2 (e_bar_prime),
    .data_o (v_bar)
);

exp_unit exp(
    .data_i (v_bar),
    .data_o (v)
);

assign prod = v * u_prime;

modulo_unit md(
    .data_i (prod),
    .data_o (u)
);

endmodule
