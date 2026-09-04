`timescale 1ns / 1ps

import rsdp_pkg::*;

module request_matrix(
    input  logic clk,
    input  logic rst,
    input  logic pulse,
    output logic request
    );
    
localparam int ENTRY = ((N_VEC - K_VEC)/16)+1;
localparam int MAX_COUNT = K_VEC*ENTRY; 

logic [10:0] q_counter,d_counter;
logic q_sig, d_sig, q_req, d_req;

always_ff @(posedge clk) begin
   if(rst)begin
      q_counter <= 0;
      q_sig     <= 0;
      q_req     <= 0;
   end else begin
      q_counter <= d_counter;
      q_sig     <= d_sig;
      q_req     <= d_req;
   end
end

always_comb begin
   d_counter = q_counter;
   d_sig = q_sig;
   if((pulse)||(q_counter > 0))begin
      d_counter = q_counter + 1;
      d_sig = 1;
      if(q_counter == MAX_COUNT)begin
         d_counter = 0;
         d_sig = 0;
      end
   end
end

assign d_req = q_sig;
assign request = q_req;
    
endmodule