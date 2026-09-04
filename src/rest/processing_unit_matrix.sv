`timescale 1ns / 1ps

import rsdp_pkg::*;

module processing_unit_matrix(
    input  logic mode,
    input  logic [Z_BIT_WIDTH-1:0] e_bar_prime_mult,
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_prime_add,
    input  logic [Z_BIT_WIDTH-1:0] e_bar_mult,
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_add,
    input  logic [P_BIT_WIDTH-1:0] u_prime_mult,
    input  logic [16*P_BIT_WIDTH-1:0] u_prime_add,
    input  logic [16*P_BIT_WIDTH-1:0] v_t,
    input  logic [16*P_BIT_WIDTH-1:0] q_mem,
    output logic [16*P_BIT_WIDTH-1:0] s_prime,
    output  logic [Z_BIT_WIDTH-1:0] v_bar_mult,
    output  logic [16*Z_BIT_WIDTH-1:0] v_bar_add
    );
genvar i;
logic [P_BIT_WIDTH-1:0] u_mult;
logic [16*P_BIT_WIDTH-1:0] u_add;

for (i = 0; i < 16; i = i + 1) begin:processor_b
    p_matrix_b pmb(
    .e_bar        (e_bar_add[(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH]),
    .e_bar_prime  (e_bar_prime_add[(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH]),
    .u_prime      (u_prime_add[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
    .u            (u_add[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
    .v_bar        (v_bar_add[(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH])
    );
end 
    
p_matrix_b pmb_mult(
    .e_bar        (e_bar_mult),
    .e_bar_prime  (e_bar_prime_mult),
    .u_prime      (u_prime_mult),
    .u            (u_mult),
    .v_bar        (v_bar_mult)
); 

for (i = 0; i < 16; i = i + 1) begin:processor_a
    p_matrix_a pma(
       .mode  (mode),
       .u_mul (u_mult),
       .u_add (u_add[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
       .v_t   (v_t[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
       .q_mem (q_mem[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
       .out   (s_prime[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH])
    );
end 
    
endmodule
