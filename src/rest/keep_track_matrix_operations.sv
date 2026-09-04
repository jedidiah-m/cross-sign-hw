`timescale 1ns / 1ps

import rsdp_pkg::*;

module keep_track_matrix_operations(
    input  logic clk,
    input  logic rst,
    input  logic ended_matrix,
    input  logic lower_flag,
//    input  logic clear_counter,
    output logic flag
    );
    
logic [9:0] q_count, d_count;
logic q_flag,d_flag;

always_ff @(posedge clk) begin
   if(rst)begin
      q_flag        <= 0;
      q_count       <= 0;
   end else begin
      q_flag        <= d_flag;
      q_count       <= d_count;
   end
end
    
always_comb begin
   d_count = q_count;
   if(ended_matrix)begin
      d_count = q_count + 1;
   end else if(q_count == T_VEC)begin
      d_count = 0;
   end
end

always_comb begin
   d_flag = q_flag;
   if(((d_count[1:0] == 0)&&(q_count[1:0] == 3)&&(!(d_count == 0)))||((d_count == T_VEC)&&(q_count == T_VEC-1)))begin
      d_flag = 1;
   end else if(lower_flag)begin
      d_flag = 0; 
   end
end
    
assign flag = q_flag;   
    
endmodule