`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module matrix_processor(
    input  logic clk,
    input  logic rst,
    input  logic mode,
    input  logic shift_single,
    input  logic [Z_BIT_WIDTH-1:0] e_bar_prime_mult,
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_prime_add,
    input  logic [Z_BIT_WIDTH-1:0] e_bar_mult,
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_add,
    input  logic [P_BIT_WIDTH-1:0] u_prime_mult,
    input  logic [16*P_BIT_WIDTH-1:0] u_prime_add,
    input  logic write_vt,
    input  logic [16*P_BIT_WIDTH-1:0] v_t,
    input  logic push_v,
    output logic [w-1:0] compressed_v,
    input  logic push_s,
    output logic ended,
    output logic [w-1:0] compressed_s
    );

logic [16*P_BIT_WIDTH-1:0] q_mem;
logic [16*P_BIT_WIDTH-1:0] s_prime;
logic [Z_BIT_WIDTH-1:0] v_bar_mult;
logic [16*Z_BIT_WIDTH-1:0] v_bar_add;

processing_unit_matrix pu_matrix(
    .mode            (mode),
    .e_bar_prime_mult(e_bar_prime_mult),
    .e_bar_prime_add (e_bar_prime_add),
    .e_bar_mult      (e_bar_mult),
    .e_bar_add       (e_bar_add),
    .u_prime_mult    (u_prime_mult),
    .u_prime_add     (u_prime_add),
    .v_t             (v_t),
    .q_mem           (q_mem),
    .s_prime         (s_prime),
    .v_bar_mult      (v_bar_mult),
    .v_bar_add       (v_bar_add)
    );

memory_v_matrix v_vector(
    .clk            (clk),
    .rst            (rst),
    .shift_single   (shift_single),
    .single_result  (v_bar_mult),
    .mde            (mode),
    .parallel_result(v_bar_add),
    .push_out       (push_v),
    .compressed     (compressed_v)
    );

memory_s syndrome(
    .clk       (clk),
    .rst       (rst),
    .write_vt  (write_vt),
    .mde       (mode),
    .access    (push_s),
    .in_memory (s_prime),
    .out_memory(q_mem),
    .public_key(compressed_s),
    .ended     (ended)
    );
    
endmodule
