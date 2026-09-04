`timescale 1ns / 1ps

import rsdp_pkg::*;

module chall_string(
  input logic clk,
  input logic rst,
  input logic [8:0] wa,
  input logic wdata,
  input logic [8:0] ra,
  input logic write,
  input logic rearr,
  output logic rdata
  );

logic [0 : T_VEC-1] q_st,d_st;

always_ff @(posedge clk) begin
   if(rst)begin
      q_st [0 : W_VEC-1] <= '{default: '1};
      q_st [W_VEC : T_VEC-1] <= '{default: '0};
   end else begin
      q_st <= d_st;
   end
end

always_comb begin
   d_st = q_st;
   if(rearr)begin
      d_st [0 : W_VEC-1] = '{default: '1};
      d_st [W_VEC : T_VEC-1] = '{default: '0};      
   end else if(write && (wa < T_VEC))begin
      d_st[wa] = wdata;
   end
end

always_comb begin
   rdata = 0;
   if(ra < T_VEC)begin 
      rdata = q_st[ra];
   end
end

endmodule
