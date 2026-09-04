`timescale 1ns / 1ps

import keccak_pkg::*;

module shake_input_control(
    input  logic clk,
    input  logic rst,
    input  logic init,
    input  logic switch,
    input  logic ready_o,
    input  logic valid_i,
    input  logic clear_in,
    input  logic[w-1:0] data_i,
    input  logic[w-1:0] data_i2,
    input  logic[w-1:0] data_i3,
    input  logic[w-1:0] data_i4,
    input  logic reset_logic,
    output logic ready_o_out,
    output logic valid_i_out,
    output logic clear_in_out,
    output logic[w-1:0] data_i_out,
    output logic shake_reset
    );
logic [4:0] q_count, d_count;
logic q0,d0,q1,d1,q2,d2,q,d;

always_ff @(posedge clk) begin
   if(rst)begin
      q_count <= 0;
      q0      <= 0;
      q1      <= 0;
      q2      <= 0;
      q       <= 0;
   end else begin
      q_count <= d_count;
      q0      <= d0;
      q1      <= d1;
      q2      <= d2;
      q       <= d;
   end
end

assign d = reset_logic|((clear_in)&((q_count == 1)|(q_count == 2)|(q_count == 3)));
assign d0 = q;
assign d1 = q0;
assign d2 = d0|d1|q1;
assign shake_reset = q2;

always_comb begin
   d_count = q_count;
   if(switch)begin
      d_count = q_count + 1;
//      if(init)begin
//         d_count = 0;
//      end
   end
end

always_comb begin
   data_i_out = 0;
      case(q_count)
         0       : data_i_out = data_i;
         1       : data_i_out = data_i2;
         2       : data_i_out = data_i3;
         3       : data_i_out = data_i4;
         default : data_i_out = 0;
      endcase
end

assign ready_o_out = ready_o;
assign valid_i_out = valid_i;
assign clear_in_out = clear_in;
    
endmodule