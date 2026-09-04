`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module read_cmt_unit(
    input  logic clk,
    input  logic rst,
    input  logic [1:0]select_branch_cmt0,
    input  logic req_cmt_0,
    input  logic req_cmt_1,
    output logic [14:0] raddress,
    output logic req
    );
    
localparam int CMT0_INITIAL_ADD_0 = ((LAMBDA/w)*T_VEC); 
localparam int CMT0_DURATION_0 = (((2*LAMBDA)/w)*LEAVES[0]); 

localparam int CMT0_INITIAL_ADD_1 = ((LAMBDA/w)*T_VEC)+(((2*LAMBDA)/w)*LEAVES[0]); 
localparam int CMT0_DURATION_1 = (((2*LAMBDA)/w)*LEAVES[1]); 

localparam int CMT0_INITIAL_ADD_2 = ((LAMBDA/w)*T_VEC)+(((2*LAMBDA)/w)*LEAVES[0])+(((2*LAMBDA)/w)*LEAVES[1]); 
localparam int CMT0_DURATION_2 = (((2*LAMBDA)/w)*LEAVES[2]); 

localparam int CMT0_INITIAL_ADD_3 = ((LAMBDA/w)*T_VEC)+(((2*LAMBDA)/w)*LEAVES[0])+(((2*LAMBDA)/w)*LEAVES[1])+(((2*LAMBDA)/w)*LEAVES[2]); 
localparam int CMT0_DURATION_3 = (((2*LAMBDA)/w)*LEAVES[3]); 

localparam int CMT1_INITIAL_ADD = (((3*LAMBDA)/w)*T_VEC);    
localparam int CMT1_DURATION = (((2*LAMBDA)/w)*T_VEC); 

logic [14:0]  d_max_count,q_max_count,q_count,d_count;
logic [5:0] d_block_count,q_block_count;
logic [3:0] req_group;
logic req_sense;

always_ff @(posedge clk) begin
   if(rst)begin
      q_max_count   <= 0;
      q_count       <= 0;
      q_block_count <= 0;
   end else begin
      q_max_count   <= d_max_count;
      q_count       <= d_count;
      q_block_count <= d_block_count;
   end
end

assign req_group = {select_branch_cmt0[1],select_branch_cmt0[0],req_cmt_0,req_cmt_1};
assign req_sense =  select_branch_cmt0[1]|select_branch_cmt0[0]|req_cmt_0|req_cmt_1 ;

always_comb begin
   d_max_count = q_max_count;
   d_count = q_count;
   if((req_sense)&&(!req))begin
      case(req_group)
         4'b0010:begin
            d_max_count = CMT0_INITIAL_ADD_0 + CMT0_DURATION_0;
            d_count     = CMT0_INITIAL_ADD_0;
         end
         4'b0110:begin
            d_max_count = CMT0_INITIAL_ADD_1 + CMT0_DURATION_1;
            d_count     = CMT0_INITIAL_ADD_1;
         end
         4'b1010:begin
            d_max_count = CMT0_INITIAL_ADD_2 + CMT0_DURATION_2;
            d_count     = CMT0_INITIAL_ADD_2;
         end
         4'b1110:begin
            d_max_count = CMT0_INITIAL_ADD_3 + CMT0_DURATION_3;
            d_count     = CMT0_INITIAL_ADD_3;
         end
         4'b0001:begin
            d_max_count = CMT1_INITIAL_ADD + CMT1_DURATION;
            d_count     = CMT1_INITIAL_ADD;
         end
      endcase
   end else if(q_count < q_max_count)begin
      d_count = q_count + 1;
      if(q_block_count >= B_SIZE)begin
         d_count = q_count;
      end
   end
end

assign req = ((q_count < q_max_count)&&((q_block_count < B_SIZE)));

assign raddress = (req) ? q_count : 0 ;

always_comb begin
   d_block_count = q_block_count + 1;
   if((q_block_count == 23)||(q_count == q_max_count))begin
      d_block_count = 0;
   end
end
    
endmodule