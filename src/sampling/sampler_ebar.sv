`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sampler_ebar(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] data_in,
    input  logic valid_o,
    output logic interrupt,
    output logic finished,
    output logic write_out,
    output logic [16*Z_BIT_WIDTH-1:0] place_memory
    );
    
logic [3*Z_BIT_WIDTH-1:0] data_b;
logic shift_serial,shift_parallel,ready_true,ended,valid_serial,valid_parallel;
logic [Z_BIT_WIDTH-1:0] data_serial;
logic [3*Z_BIT_WIDTH-1:0] data_parallel;

assign finished = ended;
 
samplefz_fifo fifo(
        .clk  (clk),
        .reset (rst),
        .valid_o (valid_o),
        .finished (ended),
        .data_in (data_in),
        .shift_serial (shift_serial),
        .shift_parallel (shift_parallel),
        .data_out (data_b)
);

sampler_fz sampler_unit(
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

store_ebar store(
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

endmodule
