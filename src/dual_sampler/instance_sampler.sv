`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module instance_sampler(
    input  logic clk,
    input  logic rst,
    input  logic valid_o,
    input  logic [w-1:0] data_in,
    output logic sample_type,
    output logic interrupt,
    output logic finished_e,
    output logic write_out_e,
    output logic [16*Z_BIT_WIDTH-1:0] place_memory_e,
    output logic finished_u,
    output logic write_out_u,
    output logic [16*P_BIT_WIDTH-1:0] place_memory_u
    );
    
logic [3*Z_BIT_WIDTH-1:0] parallel_fz;
logic [9*P_BIT_WIDTH-1:0] parallel_fp;
logic [7:0] bit_counter;
    
e_bar_uprime_fifo fifo(
    .clk(clk),
    .rst(rst),
    .valid_o,
    .sample_type(sample_type),
    .data_in(data_in),
    .clr(clr),
    .shift_single_fz(shift_single_fz),
    .shift_single_fp(shift_single_fp),
    .shift_parallel_fz(shift_parallel_fz),
    .shift_parallel_fp(shift_parallel_fp),
    .interrupt(interrupt),
    .bit_counter(bit_counter),
    .parallel_fz(parallel_fz),
    .parallel_fp(parallel_fp)
);

e_bar_u_prime_sampler sampler(
    .clk(clk),
    .rst(rst),
    .interrupt(interrupt),
    .bit_counter(bit_counter),
    .parallel_fz(parallel_fz),
    .parallel_fp(parallel_fp),
    .blast_output(blast_output),
    .finish_process(finish_process),
    .clr(clr),
    .sample_type(sample_type),
    .shift_single_fz(shift_single_fz),
    .shift_single_fp(shift_single_fp),
    .shift_parallel_fz(shift_parallel_fz),
    .shift_parallel_fp(shift_parallel_fp),
    .valid_single_fz(valid_single_fz),
    .valid_single_fp(valid_single_fp),
    .valid_parallel_fz(valid_parallel_fz),
    .valid_parallel_fp(valid_parallel_fp)
);

store_ebar_prime store_e(
    .clk(clk),
    .reset(rst),
    .sample_type(sample_type),
    .blast_output(blast_output),
    .finish_process(finish_process),
    .valid_parallel(valid_parallel_fz),
    .valid_serial(valid_single_fz),
    .data_parallel(parallel_fz),
    .finished(finished_e),
    .write_out(write_out_e),
    .place_memory(place_memory_e)
);

store_uprime store_u(
    .clk(clk),
    .reset(rst),
    .sample_type(sample_type),
    .blast_output(blast_output),
    .finish_process(finish_process),
    .valid_parallel(valid_parallel_fp),
    .valid_serial(valid_single_fp),
    .data_parallel(parallel_fp),
    .finished(finished_u),
    .write_out(write_out_u),
    .place_memory(place_memory_u)
);
    
endmodule
