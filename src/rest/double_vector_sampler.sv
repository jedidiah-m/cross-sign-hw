`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*; 

module double_vector_sampler(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] data_in_module,
    input  logic valid_in_module,
    input  logic ready_o_system,
    output logic ready_o,
    output logic finished_e,
    output logic write_out_e,
    output logic [16*Z_BIT_WIDTH-1:0] place_memory_e,
    output logic finished_u,
    output logic write_out_u,
    output logic [16*P_BIT_WIDTH-1:0] place_memory_u
    );
    
logic [w-1:0] data_out_module;

input_instance  in_stage(
    .clk                 (clk),
    .reset               (rst),
    .data_in_module      (data_in_module),
    .valid_in_module     (valid_in_module),
    .interrupt_in_module (interrupt_in_module),
    .sample_type         (sample_type),
    .clr                 (finished_u),
    .data_out_module     (data_out_module),
    .valid_out_module    (valid_out_module),
    .interrupt_out_module(interrupt_out_module)
    );
    
instance_sampler out_stage(
    .clk           (clk),
    .rst           (rst),
    .valid_o       (valid_out_module),
    .data_in       (data_out_module),
    .sample_type   (sample_type),
    .interrupt     (interrupt_in_module),
    .finished_e    (finished_e),
    .write_out_e   (write_out_e),
    .place_memory_e(place_memory_e),
    .finished_u    (finished_u),
    .write_out_u   (write_out_u),
    .place_memory_u(place_memory_u)
    );  
    
assign ready_o = ready_o_system & (~interrupt_out_module);
    
endmodule
