`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module ch1_buffer(
    input  logic clk,
    input  logic reset,
    input  logic valid_o,
    input  logic [w-1:0] data_in,
    input  logic finished,
    input  logic shift,
    output logic [P_BIT_WIDTH-1:0] data_out
    );
    
logic [(P_BIT_WIDTH*w)-1:0] d_fifo,q_fifo;
logic [P_BIT_WIDTH-1:0] rev_data_out;
logic [w-1:0] rev_data_in;

function logic [P_BIT_WIDTH-1:0] seven_bit_switch(input logic [P_BIT_WIDTH-1:0] x);
      logic [P_BIT_WIDTH-1:0] result;
      for (int i = 0; i < P_BIT_WIDTH; i++) begin
        result[i] = x[P_BIT_WIDTH - 1 - i];
      end
      return result;
endfunction

function logic [w-1:0] quad_switch(input logic [w-1:0] x);
      logic [w-1:0] result;
      for (int i = 0; i < 8; i++) begin
         for (int j = 0; j < 8; j++) begin
            result[(8*i + j)] = x[8*i + 7 - j];
         end
      end
      return result;
endfunction

always_ff @(posedge clk)begin
   if(reset)begin
      q_fifo  <= 0;
   end else begin
      q_fifo  <= d_fifo;
   end
end

always_comb begin
   d_fifo = q_fifo;
   if(finished)begin
      d_fifo = 0;
   end else begin
       if((valid_o) && (!shift))begin 
          d_fifo = {q_fifo,rev_data_in};
       end
       if((!valid_o) && (shift))begin 
          d_fifo = {q_fifo,7'b0};
       end    
   end
end

assign rev_data_out = q_fifo[(P_BIT_WIDTH*w)-1 -: P_BIT_WIDTH];
assign rev_data_in = quad_switch(data_in);
assign data_out = seven_bit_switch(rev_data_out);

endmodule