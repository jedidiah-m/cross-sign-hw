`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module second_challenge_sampler(
    input  logic clk,
    input  logic rst,
    input  logic ready_o_system,
    input  logic valid_o,
    input  logic [w-1:0] data_o,
    input  logic increment,
    input  logic restart,
    output logic challenge,
    output logic clr,
    output logic ready_o
    );
    
logic [3:0] bits_required;   
logic [9:0] bit_counter,candidate_pos;
    
assign ready_o = ready_o_system & (~interrupt);
    
ch2_fifo fifo(
    .clk          (clk),
    .rst          (rst),
    .valid_o      (valid_o),
    .data_in      (data_o),
    .shift_coeff  (shift_coeff),
    .bits_required(bits_required),
    .clr          (clr),
    .interrupt    (interrupt),
    .bit_counter  (bit_counter),
    .candidate_pos(candidate_pos)
    );
    
ch2_sampler sampler(
    .clk          (clk),
    .rst          (rst),
    .interrupt    (interrupt),
    .restart      (restart),
    .increment    (increment),
    .bit_counter  (bit_counter),
    .candidate_pos(candidate_pos),
    .clr          (clr),
    .shift_coeff  (shift_coeff),
    .bits_required(bits_required),
    .challenge    (challenge)
    );
    
endmodule
