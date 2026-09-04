`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

localparam int       MAX_COUNT_VT = N_VEC;
localparam int         PARTIAL_VT = (N_VEC) % 16;
localparam int       COL_COUNT_VT = (N_VEC) / 16;

module store_ebar(
    input  logic clk,
    input  logic reset,
    input  logic valid_parallel,
    input  logic valid_serial,
    input  logic [Z_BIT_WIDTH-1:0] data_serial,
    input  logic [3*Z_BIT_WIDTH-1:0] data_parallel,
    output logic finished,
    output logic write_out,
    output logic [16*Z_BIT_WIDTH-1:0] place_memory
    );
    
logic [53:0] d_buffer, q_buffer;
logic [$clog2(MAX_COUNT_VT)-1:0] d_inputs,q_inputs;
logic [4:0] d_buffer_count,q_buffer_count,pointer;
logic [3:0] q_sub_counter,d_sub_counter;
logic [PARTIAL_VT*Z_BIT_WIDTH-1:0] partial_vt_result;
logic [16*Z_BIT_WIDTH-1:0] full_result;
logic d_write,d_finished,q_finished,fin;
    
always_ff @(posedge clk)begin
   if(reset)begin
      q_buffer <= 0;
      q_inputs  <= 0;
      q_buffer_count <= 0;
      q_sub_counter <= 0;
      q_finished <= 0;
   end else begin
      q_buffer <= d_buffer;
      q_inputs <= d_inputs;
      q_buffer_count <= d_buffer_count;
      q_sub_counter <= d_sub_counter;
      q_finished <= d_finished;
   end
end

always_comb begin
   d_write = 0;
   d_buffer = q_buffer;
   d_inputs = q_inputs;
   d_buffer_count = q_buffer_count;
   d_sub_counter = q_sub_counter;
if(fin)begin
   d_write = 0;
   d_buffer = 0;
   d_inputs = 0;
   d_buffer_count = 0;
   d_sub_counter = 0;
end else begin
   if((valid_serial) && (!valid_parallel))begin
      d_buffer = {q_buffer[50:0],data_serial};
      d_buffer_count = q_buffer_count + 1;
      if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_COUNT_VT)begin
               d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 1;
         if(q_sub_counter == COL_COUNT_VT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL_VT;
               if(q_inputs >= MAX_COUNT_VT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL_VT + 1;
         end
      end
   end
   
   if((!valid_serial) && (valid_parallel))begin
      d_buffer = {q_buffer[44:0],data_parallel};
      d_buffer_count = q_buffer_count + 3;
     if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_COUNT_VT)begin
                  d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 3;
         if(q_sub_counter == COL_COUNT_VT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL_VT;
               if(q_inputs >= MAX_COUNT_VT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL_VT + 3;
         end
      end
   end
   
   if((!valid_serial) && (!valid_parallel))begin
      d_buffer = q_buffer;
      d_buffer_count = q_buffer_count;
     if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_COUNT_VT)begin
                  d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000;
         if(q_sub_counter == COL_COUNT_VT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL_VT;
               if(q_inputs >= MAX_COUNT_VT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL_VT;
         end
      end
   end
end
end 
 

always_comb begin
pointer = q_buffer_count-1; 
   if(q_buffer_count == 0)
      pointer = 0;
end      
    //turn finished into a pulse_ do this on the other module aswell
always_comb begin
d_finished = q_finished; 
   if(q_inputs == MAX_COUNT_VT)
      d_finished = 1;
end  

assign fin = d_finished & (!q_finished);
assign finished = fin;
assign write_out = d_write;

always_comb begin
   place_memory = 0;
   if(d_write) begin
      place_memory = full_result;
      if(q_sub_counter == COL_COUNT_VT)begin
         place_memory[16*Z_BIT_WIDTH-1:(16-PARTIAL_VT)*Z_BIT_WIDTH] = partial_vt_result;
         place_memory[(16-PARTIAL_VT)*Z_BIT_WIDTH-1:0] = 0;
      end
   end
end

always_comb begin
   partial_vt_result = 0;
   full_result = 0;
   case(pointer)
   'd17:begin
       partial_vt_result = q_buffer[18*Z_BIT_WIDTH-1 -: PARTIAL_VT*Z_BIT_WIDTH];
       full_result = q_buffer[18*Z_BIT_WIDTH-1 -: 16*Z_BIT_WIDTH];
   end
   'd16:begin
       partial_vt_result = q_buffer[17*Z_BIT_WIDTH-1 -: PARTIAL_VT*Z_BIT_WIDTH];
       full_result = q_buffer[17*Z_BIT_WIDTH-1 -: 16*Z_BIT_WIDTH];
   end
   'd15:begin
       partial_vt_result = q_buffer[16*Z_BIT_WIDTH-1 -: PARTIAL_VT*Z_BIT_WIDTH];
       full_result = q_buffer[16*Z_BIT_WIDTH-1 -: 16*Z_BIT_WIDTH];
   end
   default:begin
      partial_vt_result = 0;
      full_result = 0;
   end
   endcase
end     
 
endmodule