`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module prepare_resp_yv(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0]data_in,
    input  logic write_yv,
    input  logic restart_flush,
    output logic [w-1:0]data_out,
    output logic valid_out
    );
    
logic [5:0] q_count,d_count;
logic [2:0]bytes;

always_ff @(posedge clk)begin
   if(rst)
      q_count <= 0;
   else 
      q_count <= d_count;
   end
   
always_comb begin
   d_count = q_count;
   bytes   = 0;
   if(write_yv)begin
      d_count = q_count + 1;
      if(q_count == Y_SIZE - 1)begin
         bytes = Y_REM;
      end
      if(q_count == Y_SIZE + V_SIZE - 1)begin
         bytes = V_REM;
         d_count = 0;
      end
   end
end

comp_unit compression(
    .clk      (clk),
    .reset    (rst),
    .shift_in (write_yv),
    .bytes    (bytes),
    .data_in  (data_in),
    .flush    (restart_flush),
    .data_out (data_out),     //
    .valid_out(valid_out)      //
    );
    
endmodule