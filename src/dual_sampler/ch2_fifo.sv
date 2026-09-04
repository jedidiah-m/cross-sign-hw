`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module ch2_fifo(
    input  logic clk,
    input  logic rst,
    input  logic valid_o,
    input  logic [w-1:0] data_in,
    input  logic shift_coeff,
    input  logic [3:0] bits_required,
    input  logic clr,
    output logic interrupt,
    output logic [9:0] bit_counter,candidate_pos
    );
    
function logic [w-1:0] quad_switch(input logic [w-1:0] x);
      logic [w-1:0] result;
      for (int i = 0; i < 8; i++) begin
         for (int j = 0; j < 8; j++) begin
            result[(8*i + j)] = x[8*i + 7 - j];
         end
      end
      return result;
endfunction

function logic [9:0] endian_bit_switch(input logic [9:0] x,input logic [3:0] portsize);
      logic [9:0] result,final_result;
      result = 0;
           for (int i = 0; i < 10; i++) begin
              result[i] = x[9 - i];
           end
         case(portsize)
         4'b0001 : final_result = result[0];
         4'b0010 : final_result = result[1:0];
         4'b0011 : final_result = result[2:0];
         4'b0100 : final_result = result[3:0];
         4'b0101 : final_result = result[4:0];
         4'b0110 : final_result = result[5:0];
         4'b0111 : final_result = result[6:0];
         4'b1000 : final_result = result[7:0];
         4'b1001 : final_result = result[8:0];
         4'b1010 : final_result = result;
         default : final_result = 0;
         endcase
      return final_result;
endfunction

logic [(10*w + 9) - 1:0] q_buffer,d_buffer;
logic [9:0] q_count,d_count;
logic [3:0] q_remaining,d_remaining;
logic [3:0] q_blocks,d_blocks;
logic q_interrupt,d_interrupt;
logic [w-1:0] data_in_process;
logic [9:0] candidate_pos_process;

assign data_in_process = quad_switch(data_in);
assign interrupt = q_interrupt;
assign bit_counter = q_count;
assign candidate_pos_process = q_buffer[(10*w+9)-1 -: 10];
assign candidate_pos = endian_bit_switch(candidate_pos_process,bits_required);

always_ff @(posedge clk) begin
    if(rst)begin
       q_buffer <= '0;
       q_count <= '0;
       q_remaining <= '0;
       q_blocks <= '0;
       q_interrupt <= '0;
    end else begin
       q_buffer <= d_buffer;
       q_count <= d_count;
       q_remaining <= d_remaining;
       q_blocks <= d_blocks;
       q_interrupt <= d_interrupt;
    end
end

always_comb begin
d_blocks = q_blocks;
d_interrupt = q_interrupt;
d_remaining = q_remaining;
   if(clr)begin
      d_blocks = '0;
      d_interrupt = '0;
      d_remaining = '0;
   end else begin
      if(valid_o)begin
      d_blocks = q_blocks + 1;
         if(q_blocks == 9)begin
            d_interrupt = 1;
            d_blocks = 0;
         end
      end else if((q_blocks==0)&&(q_count < bits_required))begin
         d_remaining = q_count[3:0];
         d_interrupt = 0;
      end
   end
end

always_comb begin
d_count = q_count;
d_buffer = q_buffer;
   if(clr)begin
      d_buffer = '0;
      d_count = '0;
   end else begin
      if((valid_o)&&(!interrupt))begin
         d_count = q_count + 64;
         case(q_remaining)
         4'b0000 : d_buffer = {q_buffer[(9*w + 9)-1 : 9],data_in_process,9'b0};
         4'b0001 : d_buffer = {q_buffer[(10*w + 9)-1 -: 1],q_buffer[(9*w + 8)-1 : 8],data_in_process,8'b0};
         4'b0010 : d_buffer = {q_buffer[(10*w + 9)-1 -: 2],q_buffer[(9*w + 7)-1 : 7],data_in_process,7'b0};
         4'b0011 : d_buffer = {q_buffer[(10*w + 9)-1 -: 3],q_buffer[(9*w + 6)-1 : 6],data_in_process,6'b0};
         4'b0100 : d_buffer = {q_buffer[(10*w + 9)-1 -: 4],q_buffer[(9*w + 5)-1 : 5],data_in_process,5'b0};
         4'b0101 : d_buffer = {q_buffer[(10*w + 9)-1 -: 5],q_buffer[(9*w + 4)-1 : 4],data_in_process,4'b0};
         4'b0110 : d_buffer = {q_buffer[(10*w + 9)-1 -: 6],q_buffer[(9*w + 3)-1 : 3],data_in_process,3'b0};
         4'b0111 : d_buffer = {q_buffer[(10*w + 9)-1 -: 7],q_buffer[(9*w + 2)-1 : 2],data_in_process,2'b0};
         4'b1000 : d_buffer = {q_buffer[(10*w + 9)-1 -: 8],q_buffer[(9*w + 1)-1 : 1],data_in_process,1'b0};
         4'b1001 : d_buffer = {q_buffer[(10*w + 9)-1 -: 9],q_buffer[(9*w + 0)-1 : 0],data_in_process};
         default: d_buffer = q_buffer;
         endcase
      end else if(q_blocks==0)begin
         if(shift_coeff)begin
            d_count = q_count - bits_required;
            case(bits_required)
            4'b0001 : d_buffer = {q_buffer,1'b0};
            4'b0010 : d_buffer = {q_buffer,2'b0};
            4'b0011 : d_buffer = {q_buffer,3'b0};
            4'b0100 : d_buffer = {q_buffer,4'b0};
            4'b0101 : d_buffer = {q_buffer,5'b0};
            4'b0110 : d_buffer = {q_buffer,6'b0};
            4'b0111 : d_buffer = {q_buffer,7'b0};
            4'b1000 : d_buffer = {q_buffer,8'b0};
            4'b1001 : d_buffer = {q_buffer,9'b0};
            4'b1010 : d_buffer = {q_buffer,10'b0};
            default : d_buffer = q_buffer;
            endcase
         end
      end
   end
end

endmodule
