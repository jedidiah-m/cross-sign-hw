`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*; 

module assemble_signature(
    input  logic clk,
    input  logic rst,
    input  logic next_stage,
    input  logic [0:0]challenge,
    input  logic response,
    
    output logic [1:0] select_write,
    output logic [8:0] index,
    output logic req_seed,
    output logic req_cmt0,
    output logic req_cmt1,
    output logic req_v,
    output logic req_y,
    output logic increment,
    output logic restart
    );
    
logic q0,d0,q1,d1,q2,d2,q3,d3,sense_rsp;
logic [8:0]q_round,d_round;
logic [7:0]q_count,d_count;
typedef enum logic [1:0] {
        _IDLE,
        _EVALUATE,
        _RESP,
        _PATH_PROOF
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _IDLE;
      q_count <= 0;
      q_round <= 0;
      q0      <= 0;
      q1      <= 0;
      q2      <= 0;
      q3      <= 0;
   end else begin
      q_state <= d_state;
      q_count <= d_count;
      q_round <= d_round;
      q0      <= d0;
      q1      <= d1;
      q2      <= d2;
      q3      <= d3;
   end
end
    
assign d0 = response;
assign d1 = q0;
assign d2 = q1;
assign d3 = (~response)&(~q0)&(~q1)&(q2);
assign sense_rsp = q3;
assign index = q_round;

always_comb begin
d_state = q_state;
d_count = q_count;
d_round = q_round;
select_write = 0;
req_seed     = 0;
req_cmt0     = 0;
req_cmt1     = 0;
req_v        = 0;
req_y        = 0;
increment    = 0;
restart      = 0;
   case(q_state)
      _IDLE:begin
         if(next_stage)begin
            increment = 1;
            d_count = 0;
            d_round = 0;
            d_state = _EVALUATE;
         end
      end
      _EVALUATE:begin
         d_count = 0;
         if(q_round == T_VEC)begin
            d_state = _IDLE;
            d_round = 0;
            restart = 1;
         end else begin
            if(challenge == 1)begin
               d_state = _PATH_PROOF;
               req_seed = 1;
               req_cmt0 = 1;
            end else begin
               d_state = _RESP;
               req_cmt1 = 1;
               req_y    = 1;
            end
         end
      end
      _RESP:begin
         d_count = q_count + 1;
         select_write = 2'b10;
            if(q_count == Y_SIZE + 1)begin
               req_v    = 1;
            end
            if(sense_rsp)begin
               increment = 1;
               d_round = q_round + 1;
               d_state = _EVALUATE;
            end
      end
      _PATH_PROOF:begin
         d_count = q_count + 1;
         select_write = 2'b01;
            if(sense_rsp)begin
               increment = 1;
               d_round = q_round + 1;
               d_state = _EVALUATE;
            end
      end
      default:begin
         d_state = _IDLE;
      end
   endcase
end

endmodule