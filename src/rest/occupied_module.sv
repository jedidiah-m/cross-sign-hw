`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module occupied_module(
    input  logic clk,
    input  logic rst,
    input  logic shift_seed_sk,
    input  logic shift_seed_lambda,
    input  logic shift_salt,
    input  logic raise,
    input  logic finished_vt,
    output logic occupied,
    output logic start_tree_gen
    );
    
logic q_occupied,d_occupied;
logic pulse;
logic[4:0] d_counter, q_counter;
typedef enum logic [5:0] {
        IDLE,
        SEED_SK,
        SEED_SALT
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state    <= IDLE;
      q_counter  <= 0;
      q_occupied <= 0;
   end else begin
      q_state    <= d_state;
      q_counter  <= d_counter;
      q_occupied <= d_occupied;
   end
end 
     
always_comb begin
   d_occupied = q_occupied;
   if(pulse||raise)begin
      d_occupied = 1;
   end else if(finished_vt)begin
      d_occupied = 0;
   end
end

assign occupied = q_occupied;
    
always_comb begin
   d_counter = q_counter;
   d_state   = q_state;
   start_tree_gen = 0;
   pulse = 0;
   case(q_state)
      IDLE:begin
         d_state = SEED_SK;
      end
      SEED_SK:begin
         if((shift_seed_sk))begin
            d_counter = q_counter + 1;
            if(q_counter == ((2*LAMBDA)/w)-1)begin
               d_counter = 0;
               d_state = SEED_SALT;
               pulse = 1;
            end
         end
      end
      SEED_SALT:begin
         if(((shift_seed_lambda)||(shift_salt)))begin
            d_counter = q_counter + 1;
            if(q_counter == ((3*LAMBDA)/w)-1)begin
               d_counter = 0;
               d_state = IDLE;
               pulse = 1;
               start_tree_gen = 1;
            end
         end
      end
   endcase
end
       
endmodule