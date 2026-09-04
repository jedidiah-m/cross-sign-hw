`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module ch1_sampler(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] data_in,
    input  logic valid_o,
    input  logic ready_o_system,
    input  logic shift_out,
    output logic ready_o,
    output logic finished,
    output logic [(4*P_BIT_WIDTH)-1:0] first_challenge
    );

logic [w-2:0] data_b;
logic shift_serial,shift_parallel,ended,valid_serial,valid_parallel;
logic [P_BIT_WIDTH-1:0] data_serial;
logic [9*P_BIT_WIDTH-1:0] data_parallel;

logic interrupt;
logic write_out;
logic [16*P_BIT_WIDTH-1:0] place_memory;

assign finished = ended;
assign ready_o = ready_o_system & (~interrupt);
 
sample_ch1_fifo fifo(
        .clk  (clk),
        .reset (rst),
        .valid_o (valid_o),
        .finished (ended),
        .data_in (data_in),
        .shift_serial (shift_serial),
        .shift_parallel (shift_parallel),
        .data_out (data_b)
);

sampler_ch1 sampler_unit(
        .clk  (clk),
        .reset (rst),
        .valid_o (valid_o),
        .finished (ended),
        .interrupt (interrupt),
        .data_in (data_b),
        .shift_serial (shift_serial),
        .shift_parallel (shift_parallel),
        .valid_serial (valid_serial),
        .valid_parallel (valid_parallel),
        .data_serial (data_serial),
        .data_parallel (data_parallel)
);

store_ch1 store(
        .clk (clk),
        .reset (rst),
        .valid_parallel (valid_parallel),
        .valid_serial (valid_serial),
        .data_serial (data_serial),
        .data_parallel (data_parallel),
        .finished (ended),
        .write_out (write_out),
        .place_memory (place_memory)
);

memory_ch1 mem(
    .clk            (clk),
    .rst            (rst),
    .write_out      (write_out),
    .place_memory   (place_memory),
    .shift_out      (shift_out),
    .first_challenge(first_challenge)
    );

endmodule

