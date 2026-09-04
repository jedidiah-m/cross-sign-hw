`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module arithmetic_unit(
    input  logic clk,
    input  logic rst,
    input  logic write_vt,
    input  logic finished_vt,
    input  logic [16*P_BIT_WIDTH-1:0] v_t,
    input  logic [P_BIT_WIDTH-1:0] chall_1,
    input  logic push_v1,
//    input  logic push_v2,
    input  logic push_s,
    input  logic push_y,
//    input  logic matrix_pulse,
//    input  logic vector_pulse,
//    input  logic vector_shift,
    input  logic write_e_bar,
    input  logic write_e_bar_prime,
    input  logic write_u_prime,
    input  logic [16*Z_BIT_WIDTH-1:0]place_e_bar,
    input  logic [16*Z_BIT_WIDTH-1:0]place_e_bar_prime,
    input  logic [16*P_BIT_WIDTH-1:0]place_u_prime,
    output logic [w-1:0]comp_v1,
//    output logic [w-1:0]comp_v2,
    output logic [w-1:0]comp_s,
    output logic ended,
    output logic [w-1:0]comp_y,
    ///new_vector_inputs
    input  logic [16*P_BIT_WIDTH-1:0]vector_u_prime,
    input  logic [16*Z_BIT_WIDTH-1:0]vector_e_bar_prime,
    input  logic response
    ///
    );
    
logic mode;
logic shift_single;

logic [Z_BIT_WIDTH-1:0] e_bar_prime_mult;
logic [16*Z_BIT_WIDTH-1:0] e_bar_prime_add;
logic [Z_BIT_WIDTH-1:0] e_bar_mult;
logic [16*Z_BIT_WIDTH-1:0] e_bar_add;
logic [P_BIT_WIDTH-1:0] u_prime_mult;
logic [16*P_BIT_WIDTH-1:0] u_prime_add;

logic [16*P_BIT_WIDTH-1:0] delay_v_t;
logic delay_finished_vt,delay_write_vt;

logic [16*P_BIT_WIDTH-1:0]d_vector_u_prime;
logic [16*Z_BIT_WIDTH-1:0]d_vector_e_bar_prime;
logic d_response;

regn #(
    .WIDTH(16*P_BIT_WIDTH + 2)
) delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({finished_vt,       write_vt,       v_t      }),
    .data_o ({delay_finished_vt, delay_write_vt, delay_v_t})
);

regn #(
    .WIDTH(16*P_BIT_WIDTH + 16*Z_BIT_WIDTH + 1)
) another_delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({vector_u_prime,   vector_e_bar_prime,   response  }),
    .data_o ({d_vector_u_prime, d_vector_e_bar_prime, d_response})
);
    
matrix_processor   mp(
    .clk             (clk),
    .rst             (rst),
    .mode            (mode),
    .shift_single    (shift_single),
    .e_bar_prime_mult(e_bar_prime_mult),
    .e_bar_prime_add (e_bar_prime_add),
    .e_bar_mult      (e_bar_mult),
    .e_bar_add       (e_bar_add),
    .u_prime_mult    (u_prime_mult),
    .u_prime_add     (u_prime_add),
    .write_vt        (delay_write_vt),
    .v_t             (delay_v_t),
    .push_v          (push_v1),
    .compressed_v    (comp_v1),
    .push_s          (push_s),
    .ended           (ended),
    .compressed_s    (comp_s)
    );
    
vector_processor   vp(
    .clk          (clk),
    .rst          (rst),
    .e_bar_prime  (d_vector_e_bar_prime),
    .chall_1      (chall_1),
    .u_prime      (d_vector_u_prime),
    
    .shift_input_y(d_response),
    .push_out_y   (push_y),
    
    .compressed_y (comp_y)
    );
    


memory_e_bar #(
    .DATA_WIDTH(Z_BIT_WIDTH)
) e_bar(
    .clk          (clk),
    .rst          (rst),
    .write_ebar   (write_e_bar),
    .write_vt     (delay_write_vt),
    .place_ebar   (place_e_bar),
    .finished_vt  (delay_finished_vt),
    .mode         (mode),
    .shift_single (shift_single),
    .array_add    (e_bar_add),
    .e_bar_mul    (e_bar_mult)
    );

memory_e_bar #(
    .DATA_WIDTH(Z_BIT_WIDTH)
) e_bar_prime(
    .clk          (clk),
    .rst          (rst),
    .write_ebar   (write_e_bar_prime),
    .write_vt     (delay_write_vt),
    .place_ebar   (place_e_bar_prime),
    .finished_vt  (delay_finished_vt),
    .mode         (),
    .shift_single (),
    .array_add    (e_bar_prime_add),
    .e_bar_mul    (e_bar_prime_mult)
    );
    
memory_e_bar #(
    .DATA_WIDTH(P_BIT_WIDTH)
) u_prime(
    .clk          (clk),
    .rst          (rst),
    .write_ebar   (write_u_prime),
    .write_vt     (delay_write_vt),
    .place_ebar   (place_u_prime),
    .finished_vt  (delay_finished_vt),
    .mode         (),
    .shift_single (),
    .array_add    (u_prime_add),
    .e_bar_mul    (u_prime_mult)
    );
    
endmodule
