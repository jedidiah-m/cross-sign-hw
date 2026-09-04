`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module read_seeds(
    input  logic clk,
    input  logic rst,
    input  logic finished_tree,
    input  logic get_other_seeds,
    output logic [8:0] index,
    output logic req_seed
    );
    
localparam int PAUSE = (LAMBDA/w) + 1; 

logic [3:0] q_count, d_count;
logic [8:0] q_t, d_t, value;
typedef enum logic [5:0] {
        IDLE,
        GET_0,
        GET_1,
        GET_2,
        GET_3
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_t     <= 0;
      q_count <= 0;
      q_state <= IDLE;
   end else begin
      q_t     <= d_t;
      q_count <= d_count;
      q_state <= d_state;
   end
end   

always_comb begin
   d_t      = q_t;
   d_count  = q_count;
   d_state  = q_state;
   value    = 0;
   req_seed = 0;
      case(q_state)
         IDLE:begin
            if(finished_tree)begin
               d_t = 0;
            end
            if(get_other_seeds)begin
               d_state = GET_0;
            end
         end
         GET_0:begin
            d_count = q_count + 1;
            if(q_count == 0)begin
               req_seed = 1;
               value    = q_t + 4;
            end
            if(q_count == PAUSE)begin
               d_count = 0;
               d_state = GET_1;
            end
         end
         GET_1:begin
            d_count = q_count + 1;
            if(q_count == 0)begin
               req_seed = 1;
               value    = q_t + 5;
            end
            if(q_count == PAUSE)begin
               d_count = 0;
               d_state = GET_2;
            end  
         end
         GET_2:begin
            d_count = q_count + 1;
            if(q_count == 0)begin
               req_seed = 1;
               value    = q_t + 6;
            end
            if(q_count == PAUSE)begin
               d_count = 0;
               d_state = GET_3;
            end   
         end
         GET_3:begin
               req_seed = 1;
               value    = q_t + 7;
               d_count = 0;
               d_state = IDLE;
               d_t     = q_t + 4;  
         end
      endcase
end
    
assign index = (value >= T_VEC) ? 0 : value;
    
endmodule
