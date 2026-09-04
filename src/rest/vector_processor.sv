`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module vector_processor(
    input  logic clk,
    input  logic rst,
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_prime,
//    input  logic [16*Z_BIT_WIDTH-1:0] e_bar,
    input  logic [P_BIT_WIDTH-1:0] chall_1,
    input  logic [16*P_BIT_WIDTH-1:0] u_prime,
    
//    input  logic shift_input_v,
    input  logic shift_input_y,
//    input  logic push_out_v,
    input  logic push_out_y,
    
//    output logic [w-1:0] compressed_v,
    output logic [w-1:0] compressed_y
    );
    
logic [16*P_BIT_WIDTH-1:0] y;
logic [16*Z_BIT_WIDTH-1:0] v_bar;
    
processing_unit_vector   pu_vector(
    .e_bar_prime(e_bar_prime),
//    .e_bar      (e_bar),
    .chall_1    (chall_1),
    .u_prime    (u_prime),
    .y          (y)
//    .v_bar      (v_bar)
    );
    
//memory_v_vector #(
//    .DATA_WIDTH(Z_BIT_WIDTH)
//) v_vec(
//    .clk            (clk),
//    .rst            (rst),
//    .shift_input    (shift_input_v),
//    .parallel_result(v_bar),
//    .push_out       (push_out_v),
//    .compressed     (compressed_v)
//    );
    
memory_v_vector #(
    .DATA_WIDTH(P_BIT_WIDTH)
) y_vec(
    .clk            (clk),
    .rst            (rst),
    .shift_input    (shift_input_y),
    .parallel_result(y),
    .push_out       (push_out_y),
    .compressed     (compressed_y)
    );
    
endmodule
