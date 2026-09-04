`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module e_bar_uprime_fifo(
    input  logic clk,
    input  logic rst,
    input  logic valid_o,
    input  logic sample_type,
    input  logic [w-1:0] data_in,
    input  logic clr,
    input  logic shift_single_fz,
    input  logic shift_single_fp,
    input  logic shift_parallel_fz,
    input  logic shift_parallel_fp,
    output logic interrupt,
    output logic [7:0] bit_counter,
    //output logic [Z_BIT_WIDTH-1:0] single_fz,
    output logic [3*Z_BIT_WIDTH-1:0] parallel_fz,
    //output logic [P_BIT_WIDTH-1:0] single_fp,
    output logic [9*P_BIT_WIDTH-1:0] parallel_fp
    );
    
function logic [9*P_BIT_WIDTH-1:0] parallel_seven_bit_switch(input logic [9*P_BIT_WIDTH-1:0] x);
      logic [9*P_BIT_WIDTH-1:0] result;
      for (int j = 0; j < 9; j++) begin
         for (int i = 0; i < P_BIT_WIDTH; i++) begin
            result[j*P_BIT_WIDTH + i] = x[j*P_BIT_WIDTH + P_BIT_WIDTH - 1 - i];
         end
      end
      return result;
endfunction

function logic [3*Z_BIT_WIDTH-1:0] parallel_triple_bit_switch(input logic [3*Z_BIT_WIDTH-1:0] x);
      logic [3*Z_BIT_WIDTH-1:0] result;
      for (int j = 0; j < 3; j++) begin
         for (int i = 0; i < Z_BIT_WIDTH; i++) begin
            result[j*Z_BIT_WIDTH + i] = x[j*Z_BIT_WIDTH + Z_BIT_WIDTH - 1 - i];
         end
      end
      return result;
endfunction

function logic [w-1:0] quad_switch(input logic [w-1:0] x);
      logic [w-1:0] result;
      for (int i = 0; i < 8; i++) begin
         for (int j = 0; j < 8; j++) begin
            result[(8*i + j)] = x[8*i + 7 - j];
         end
      end
      return result;
endfunction
    
logic [(3*w + 6) - 1:0] q_buffer,d_buffer;
logic [7:0] q_count,d_count;
logic [2:0] q_remaining,d_remaining;
logic [1:0] q_blocks,d_blocks;
logic q_interrupt,d_interrupt;
logic [w-1:0] data_in_process;
logic [3*Z_BIT_WIDTH-1:0] parallel_fz_process;
logic [9*P_BIT_WIDTH-1:0] parallel_fp_process;

 always_ff @(posedge clk) begin
    if(rst)begin
       q_buffer <= '0;
       q_count <= '0;
       q_remaining <= '0;
       q_blocks <= '0;
       q_interrupt <= '0;
    end else begin
       q_buffer <= d_buffer;
       q_count <= d_count;
       q_remaining <= d_remaining;
       q_blocks <= d_blocks;
       q_interrupt <= d_interrupt;
    end
 end
 
assign data_in_process = quad_switch(data_in);
assign parallel_fz = parallel_triple_bit_switch(parallel_fz_process);
assign parallel_fp = parallel_seven_bit_switch(parallel_fp_process);
assign interrupt = q_interrupt;
assign bit_counter = q_count;
assign parallel_fp_process = q_buffer[(3*w+6)-1 -: 63];
assign parallel_fz_process = q_buffer[(3*w+6)-1 -: 9];

always_comb begin
d_blocks = q_blocks;
d_interrupt = q_interrupt;
d_remaining = q_remaining;
if(clr)begin
   d_blocks = '0;
   d_interrupt = '0;
   d_remaining = '0;
end else begin
   if(valid_o)begin
   d_blocks = q_blocks + 1;
      if(q_blocks == 2)begin
         d_interrupt = 1;
         d_blocks = 0;
      end
   end else if((q_blocks==0)&&(((q_count==0)&&(!sample_type))||((q_count < 7)&&(sample_type))))begin
      d_remaining = q_count[2:0];
      d_interrupt = 0;
   end
end
end

always_comb begin
d_count = q_count;
d_buffer = q_buffer;
if(clr)begin
   d_buffer = '0;
   d_count = '0;
end else begin
   if((valid_o)&&(!interrupt))begin
      d_count = q_count + 64;
      case(q_remaining)
         3'b000 : d_buffer = {q_buffer[(2*w + 6)-1 : 6],data_in_process,6'b0};
         3'b001 : d_buffer = {q_buffer[(3*w + 6)-1 -: 1],q_buffer[(2*w + 5)-1 : 5],data_in_process,5'b0};
         3'b010 : d_buffer = {q_buffer[(3*w + 6)-1 -: 2],q_buffer[(2*w + 4)-1 : 4],data_in_process,4'b0};
         3'b011 : d_buffer = {q_buffer[(3*w + 6)-1 -: 3],q_buffer[(2*w + 3)-1 : 3],data_in_process,3'b0};
         3'b100 : d_buffer = {q_buffer[(3*w + 6)-1 -: 4],q_buffer[(2*w + 2)-1 : 2],data_in_process,2'b0};
         3'b101 : d_buffer = {q_buffer[(3*w + 6)-1 -: 5],q_buffer[(2*w + 1)-1 : 1],data_in_process,1'b0};
         3'b110 : d_buffer = {q_buffer[(3*w + 6)-1 -: 6],q_buffer[(2*w + 0)-1 : 0],data_in_process};
         default: d_buffer = q_buffer;
      endcase
   end else if(q_blocks==0)begin
      if(!sample_type)begin
         if(shift_single_fz)begin
            d_count = q_count - 3;
            d_buffer = {q_buffer,3'b0};
         end else if(shift_parallel_fz) begin
            d_count = q_count - 9;
            d_buffer = {q_buffer,9'b0};
         end
      end else begin
         if(shift_single_fp)begin
            d_count = q_count - 7;
            d_buffer = {q_buffer,7'b0};
         end else if(shift_parallel_fp) begin
            d_count = q_count - 63;
            d_buffer = {q_buffer,63'b0};
         end
      end
   end
end
end
    
endmodule