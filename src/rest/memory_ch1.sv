`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module memory_ch1(
    input  logic clk,
    input  logic rst,
    input  logic write_out,
    input  logic [16*P_BIT_WIDTH-1:0] place_memory,
    input  logic shift_out,
    output logic [(4*P_BIT_WIDTH)-1:0] first_challenge
    );
    
localparam int         PARTIAL = (T_VEC) % 16;
localparam int       COL_COUNT = (T_VEC) / 16;

logic [(T_VEC*P_BIT_WIDTH)-1:0] q_store,d_store;
logic [6:0] q_count,d_count;

always_ff @(posedge clk)begin
   if(rst) begin
      q_count <= 0;
      q_store <= 0;
   end else begin 
      q_count <= d_count;
      q_store <= d_store;
   end
end
///Only place where P_BIT_WIDTH IS  set to 7
always_comb begin
   d_count = q_count;
   d_store = q_store;
   if((write_out)&&(!shift_out))begin
      d_count = q_count + 1;
      d_store = {q_store,place_memory};
      if(q_count == COL_COUNT)begin
         d_count = 0;
         d_store = {q_store,place_memory[16*P_BIT_WIDTH-1  -:  PARTIAL*P_BIT_WIDTH]};
      end
   end
   if((!write_out)&&(shift_out))begin
      d_store = {q_store,7'b0};
   end
end
assign first_challenge = q_store[(T_VEC*P_BIT_WIDTH)-1 -: 4*P_BIT_WIDTH]; 
endmodule