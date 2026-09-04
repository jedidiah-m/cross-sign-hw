`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module memory_v_matrix(
    input  logic clk,
    input  logic rst,
    input  logic shift_single,
    input  logic [Z_BIT_WIDTH-1:0] single_result,
    input  logic mde,
    input  logic [16*Z_BIT_WIDTH-1:0] parallel_result,
    input  logic push_out,
    output logic [w-1:0] compressed
    );
    
localparam int NO_ADD = (N_VEC - K_VEC) / 16;
localparam int NO_ADD_FRAC = (N_VEC - K_VEC) % 16;

function logic [w-1:0] swtc(input logic [w-1:0] x);
      logic [w-1:0] result;
        for (int j = 0; j < 8; j++) begin
           for (int i = 0; i < 8; i++) begin
              result[j*8 + i] = x[j*8 + 7 - i];
           end
        end
      return result;
endfunction

function logic [16*Z_BIT_WIDTH-1:0] endian_bit_switch(input logic [16*Z_BIT_WIDTH-1:0] x);
      logic [16*Z_BIT_WIDTH-1:0] result;
        for (int j = 0; j < 16; j++) begin
           for (int i = 0; i < Z_BIT_WIDTH; i++) begin
              result[j*Z_BIT_WIDTH + i] = x[j*Z_BIT_WIDTH + Z_BIT_WIDTH - 1 - i];
           end
        end
      return result;
endfunction

logic [Z_BIT_WIDTH-1:0] rev_single_result;
logic [16*Z_BIT_WIDTH-1:0] rev_parallel_result;
logic [N_VEC*Z_BIT_WIDTH-1:0] q_array,d_array;
logic [4:0] q_counter,d_counter;

assign rev_parallel_result = endian_bit_switch(parallel_result);
assign rev_single_result[0] = single_result[2];
assign rev_single_result[1] = single_result[1];
assign rev_single_result[2] = single_result[0];
assign compressed = swtc(q_array[N_VEC*Z_BIT_WIDTH-1 -: w]);

always_ff @(posedge clk) begin
   if(rst)begin
      q_array   <= 0;
      q_counter <= 0;
   end else begin
      q_array   <= d_array;
      q_counter <= d_counter;
   end
end

always_comb begin
d_counter = q_counter;
   if((!push_out)&&(!shift_single)&&(mde))begin
      d_counter = q_counter + 1;
      if(q_counter == NO_ADD) d_counter = 0; 
   end
end

always_comb begin
d_array = q_array;
   if((push_out)&&(!shift_single)&&(!mde))begin
      d_array = {q_array,64'b0};
   end
   if((!push_out)&&(shift_single)&&(!mde))begin
      d_array = {q_array,rev_single_result};
   end
   if((!push_out)&&(!shift_single)&&(mde))begin
      d_array = {q_array,rev_parallel_result};
      if(q_counter == NO_ADD) d_array = {q_array ,rev_parallel_result[16*Z_BIT_WIDTH-1 -: NO_ADD_FRAC*Z_BIT_WIDTH]};
   end
end

endmodule
