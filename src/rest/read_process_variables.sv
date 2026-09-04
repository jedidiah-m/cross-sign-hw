`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module read_process_variables(
    input  logic clk,
    input  logic rst,
    input  logic [8:0] index,
    input  logic req_seed,
    input  logic req_cmt0,
    input  logic req_cmt1,
    input  logic req_v,
    input  logic req_y,
    output logic [14:0] raddress,
    output logic req
    );
    
localparam int SEED_INITIAL_ADD = 0; 
localparam int SEED_DURATION = ((LAMBDA/w)); 

localparam int CMT0_INITIAL_ADD = ((LAMBDA/w)*T_VEC); 
localparam int CMT0_DURATION = (((2*LAMBDA)/w)); 

localparam int CMT1_INITIAL_ADD = (((3*LAMBDA)/w)*T_VEC);    
localparam int CMT1_DURATION = (((2*LAMBDA)/w)); 

localparam int V_INITIAL_ADD = (((5*LAMBDA)/w)*T_VEC); 
localparam int V_DURATION = V_SIZE;

localparam int Y_INITIAL_ADD = (((5*LAMBDA)/w)*T_VEC) + (V_SIZE * T_VEC);
localparam int Y_DURATION = Y_SIZE;

logic [14:0]  d_max_count,q_max_count,q_count,d_count;
//logic [5:0] d_block_count,q_block_count;
logic [4:0] req_group;
logic req_sense;
    
assign req_group = {req_seed,req_cmt0,req_cmt1,req_v,req_y};
assign req_sense = req_seed|req_cmt0|req_cmt1|req_v|req_y;
    
always_ff @(posedge clk) begin
   if(rst)begin
      q_max_count <= 0;
      q_count     <= 0;
//      q_block_count <= 0;
   end else begin
      q_max_count <= d_max_count;
      q_count     <= d_count;
//      q_block_count <= d_block_count;
   end
end

always_comb begin
   d_max_count = q_max_count;
   d_count = q_count;
   if((req_sense)&&(!req))begin
      case(req_group)
         5'b10000:begin
            d_max_count = SEED_INITIAL_ADD + (SEED_DURATION*index) + SEED_DURATION;
            d_count     = SEED_INITIAL_ADD + (SEED_DURATION*index);
         end
         5'b01000:begin
            d_max_count = CMT0_INITIAL_ADD + (CMT0_DURATION*index) + CMT0_DURATION;
            d_count     = CMT0_INITIAL_ADD + (CMT0_DURATION*index);
         end
         5'b00100:begin
            d_max_count = CMT1_INITIAL_ADD + (CMT1_DURATION*index) + CMT1_DURATION;
            d_count     = CMT1_INITIAL_ADD + (CMT1_DURATION*index);
         end
         5'b00010:begin
            d_max_count = V_INITIAL_ADD + (V_DURATION*index) + V_DURATION;
            d_count     = V_INITIAL_ADD + (V_DURATION*index);
         end
         5'b00001:begin
            d_max_count = Y_INITIAL_ADD + (Y_DURATION*index) + Y_DURATION;
            d_count     = Y_INITIAL_ADD + (Y_DURATION*index);
         end
      endcase
   end else if(q_count < q_max_count)begin
      d_count = q_count + 1;
//      if(q_block_count == B_SIZE)begin
//         d_count = q_count;
//      end
   end
end

assign req = (q_count < q_max_count); //&&(!(q_block_count == B_SIZE)));

assign raddress = (req) ? q_count : 0 ;

//always_comb begin
//   d_block_count = q_block_count;
//   if(req)begin
//      d_block_count = q_block_count + 1;
//   end else if(q_block_count == B_SIZE)begin
//      d_block_count = 0;
//   end
//end
endmodule