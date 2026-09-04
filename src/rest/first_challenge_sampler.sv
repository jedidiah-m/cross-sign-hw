`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module first_challenge_sampler(
    input  logic clk,
    input  logic rst,
    input  logic [P_BIT_WIDTH-1:0] data_in,
    input  logic finish_op,
    input  logic valid_o,
    
    output logic [(4*P_BIT_WIDTH)-1:0] data_out,
    output logic start_op,
    output logic interrupt,
    output logic shift,
    output logic finish
    );
    
logic q_interrupt,d_interrupt,valid,valid_shift,q_start,d_start;
logic [6:0]q_iteration,d_iteration;
logic [8:0]q_buff_count,d_buff_count;
logic [2:0]q_corr_count,d_corr_count;
logic [(4*P_BIT_WIDTH)-1:0] q_chall,d_chall;
logic [P_BIT_WIDTH-1:0] data_in_buffer;

always_ff @(posedge clk) begin
   if(rst)begin
      q_interrupt  <= 0;
      q_iteration  <= 0;
      q_buff_count <= 0;
      q_corr_count <= 0;
      q_chall      <= 0;
      q_start      <= 0;
   end else begin
      q_interrupt  <= d_interrupt;
      q_iteration  <= d_iteration;
      q_buff_count <= d_buff_count;
      q_corr_count <= d_corr_count;
      q_chall      <= d_chall;
      q_start      <= d_start;
   end
end

always_comb begin
   d_interrupt = q_interrupt;
   if(d_buff_count == P_BIT_WIDTH*w)begin
      d_interrupt = 1;
   end else if(d_buff_count == 0)begin
      d_interrupt = 0;
   end
end

always_comb begin
   d_buff_count = q_buff_count;
   if((!shift)&&(valid_o)&&(!finish))begin
      d_buff_count = q_buff_count + w;
   end
   if((shift)&&(!valid_o)&&(!finish))begin
      d_buff_count = q_buff_count - P_BIT_WIDTH;
   end
   if((!shift)&&(!valid_o)&&(finish))begin
      d_buff_count = 0;
   end
end

always_comb begin
   d_chall = q_chall;
   d_corr_count = q_corr_count;
   if(valid_shift)begin
      d_corr_count = q_corr_count + 1;
      d_chall = {q_chall,data_in_buffer};
   end else if(finish_op) begin
      d_corr_count = 0;
   end
end

always_comb begin
   d_iteration = q_iteration;
   finish = 0;
   if(start_op)begin
      d_iteration = q_iteration + 1;
   end else if((finish_op)&&(q_iteration == LEAVES[0]))begin
      d_iteration = 0;
      finish = 1;
   end
end

assign interrupt = q_interrupt;
assign data_out = q_chall;
assign valid = (data_in < 126);
assign shift = (interrupt && (q_corr_count < 4));
assign valid_shift = valid & shift;
assign data_in_buffer = data_in + 1;
assign d_start = ((d_corr_count == 4) && (q_corr_count == 3));
assign start_op = q_start;
    
endmodule