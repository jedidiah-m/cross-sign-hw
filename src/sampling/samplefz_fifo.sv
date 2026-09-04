`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module samplefz_fifo(
    input  logic clk,
    input  logic reset,
    input  logic valid_o,
    input  logic finished,
    input  logic [w-1:0] data_in,
    input  logic shift_serial,
    input  logic shift_parallel,
    output logic [3*Z_BIT_WIDTH-1:0] data_out
    );
    
    logic [191:0] d_fifo,q_fifo;
    
    always_ff @(posedge clk)begin
        if(reset)
            q_fifo <= 0;
        else 
            q_fifo <= d_fifo;
    end
    
    always_comb begin
        d_fifo = q_fifo;
        if(finished)begin
              d_fifo = 0;
        end else begin
           if((valid_o) && (!shift_serial) && (!shift_parallel))begin 
              d_fifo = {q_fifo[127:0],data_in};
           end
           if((!valid_o) && (shift_serial) && (!shift_parallel))begin 
              d_fifo = {q_fifo[188:0],3'b0};
           end
           if((!valid_o) && (!shift_serial) && (shift_parallel))begin 
              d_fifo = {q_fifo[182:0],9'b0};
           end
        end
    end
    
    assign data_out = q_fifo[191 -: (3*Z_BIT_WIDTH)];
    
endmodule
