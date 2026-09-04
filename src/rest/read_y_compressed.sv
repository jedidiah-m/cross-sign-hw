`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module read_y_compressed(
    input  logic clk,
    input  logic rst,
    input  logic req_pulse,
    output logic[13:0] r_address,
    output logic req
    );
    
localparam int MAX_ADDRESS = (SECURITY_LVL == 1) ? 2203:
                             (SECURITY_LVL == 3) ? 5145:
                             (SECURITY_LVL == 5) ? 8836:
                                                   2203;
                                                   
logic [14:0] q_count,d_count;
logic [5:0] d_block_count,q_block_count;
    
always_ff @(posedge clk) begin
   if(rst)begin
      q_count       <= MAX_ADDRESS;
      q_block_count <= 0;
   end else begin
      q_count       <= d_count;
      q_block_count <= d_block_count;
   end
end

always_comb begin
   d_count = q_count;
   if((req_pulse)&&(!req))begin
      d_count = 0;
   end else if(q_count < MAX_ADDRESS)begin
      d_count = q_count + 1;
      if(q_block_count >= B_SIZE)begin
         d_count = q_count;
      end
   end
end

assign req = ((q_count < MAX_ADDRESS)&&((q_block_count < B_SIZE)));

assign r_address = (req) ? q_count : 0 ;

always_comb begin
   d_block_count = q_block_count + 1;
   if((q_block_count == 23)||(q_count == MAX_ADDRESS))begin
      d_block_count = 0;
   end
end
    
endmodule