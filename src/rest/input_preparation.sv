`timescale 1ns / 1ps

import keccak_pkg::*;

module input_preparation(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] s_vector,
    input  logic [w-1:0] v_vector,
    input  logic [w-1:0] y_vector,
    input  logic [w-1:0] salt,
    input  logic [w-1:0] suffix,
    input  logic [w-1:0] dig_chall,//
//    input  logic [w-1:0] suffix2,//
    input  logic s_pulse,
    input  logic v_pulse,
    input  logic y_pulse,
    input  logic salt_pulse,
    input  logic suffix_pulse,
    input  logic dig_chall_pulse,//
    input  logic suffix2_pulse,//
//    output logic flush,
    output logic valid_s,
    output logic valid_v,
    output logic valid_y,
    output logic valid_salt,
    output logic valid_suffix,
    output logic valid_dig_chall,//
    output logic valid_suffix2,//
    output logic end_pulse,
//    output logic [2:0] bytes,
//    output logic [w-1:0] data
    output logic [w-1:0] data_out,
    output logic valid_out
    );
   
logic [2:0] bytes;
logic [w-1:0] data;
    
compress_assist ca(
    .clk            (clk),
    .rst            (rst),
    .s_vector       (s_vector),
    .v_vector       (v_vector),
    .y_vector       (y_vector),
    .salt           (salt),
    .suffix         (suffix),
    .dig_chall      (dig_chall),//
//    .suffix2        (suffix2),//
    .s_pulse        (s_pulse),
    .v_pulse        (v_pulse),
    .y_pulse        (y_pulse),
    .salt_pulse     (salt_pulse),
    .suffix_pulse   (suffix_pulse),
    .dig_chall_pulse(dig_chall_pulse),//
    .suffix2_pulse  (suffix2_pulse),//
    .flush          (flush),
    .valid_s        (valid_s),
    .valid_v        (valid_v),
    .valid_y        (valid_y),
    .valid_salt     (valid_salt),
    .valid_suffix   (valid_suffix),
    .valid_dig_chall(valid_dig_chall),//
    .valid_suffix2  (valid_suffix2),//
    .end_pulse      (end_pulse),
    .bytes          (bytes),
    .data           (data)
    );
    
comp_unit cu(
    .clk      (clk),
    .reset    (rst),
    .shift_in (valid_s|valid_v|valid_y|valid_salt|valid_suffix|valid_dig_chall|valid_suffix2),
    .bytes    (bytes),
    .data_in  (data),
    .flush    (flush),
    .data_out (data_out),
    .valid_out(valid_out)
    );
    
endmodule
