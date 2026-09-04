`timescale 1ns / 1ps

import keccak_pkg::*;

module shake128or256(
    input  logic clk,
    input  logic rst,
    input  logic ready_o,
    input  logic valid_i,
    input  logic clear_in,
    output  logic ready_i,
    output  logic valid_o,
    input logic[w-1:0] data_i,
    output logic[w-1:0] data_o
    );

keccak shake_unit(
        .clk (clk),
        .rst (rst),
        .clear_in (clear_in),
        .ready_o (!ready_o),
        .valid_i (!valid_i),
        .ready_i (ready_i),
        .valid_o (valid_o),
        .data_i (data_i),
        .data_o (data_o)
);

endmodule
