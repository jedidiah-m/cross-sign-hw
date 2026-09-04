`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module store_uprime(
    input  logic clk,
    input  logic reset,
    input  logic sample_type,
    input  logic blast_output,
    input  logic finish_process,
    input  logic valid_parallel,
    input  logic valid_serial,
    input  logic [9*P_BIT_WIDTH-1:0] data_parallel,
    output logic finished,
    output logic write_out,
    output logic [16*P_BIT_WIDTH-1:0] place_memory
    );
    
localparam int       MAX_C = N_VEC;
localparam int         PART = (N_VEC) % 16;
localparam int       COL_C = (N_VEC) / 16;

logic [24*P_BIT_WIDTH-1:0] d_buffer, q_buffer;
logic [$clog2(MAX_C)-1:0] d_inputs,q_inputs;
logic [5:0] d_buffer_count,q_buffer_count,pointer;
logic [3:0] q_sub_counter,d_sub_counter;
logic [16*P_BIT_WIDTH-1:0] full_result;
logic d_write;
    
always_ff @(posedge clk)begin
   if(reset)begin
      q_buffer <= 0;
      q_inputs  <= 0;
      q_buffer_count <= 0;
      q_sub_counter <= 0;
   end else begin
      q_buffer <= d_buffer;
      q_inputs <= d_inputs;
      q_buffer_count <= d_buffer_count;
      q_sub_counter <= d_sub_counter;
   end
end
    
always_comb begin
   d_write = 0;
   d_buffer = q_buffer;
   d_inputs = q_inputs;
   d_buffer_count = q_buffer_count;
   d_sub_counter = q_sub_counter;
if(finished)begin//update
   d_write = 0;
   d_buffer = 0;
   d_inputs = 0;
   d_buffer_count = 0;
   d_sub_counter = 0;
end else begin
   if((valid_serial) && (!valid_parallel))begin
      d_buffer = {q_buffer,data_parallel[9*P_BIT_WIDTH-1 -: P_BIT_WIDTH]};
      d_buffer_count = q_buffer_count + 1;
      if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_C)begin
               d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 1;
      end
   end
   
   if((!valid_serial) && (valid_parallel))begin
      d_buffer = {q_buffer,data_parallel};
      d_buffer_count = q_buffer_count + 9;
     if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_C)begin
                  d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 9;
      end
   end
   
   if((!valid_serial) && (!valid_parallel) && (blast_output) && (sample_type))begin//same thing here
      d_buffer = q_buffer;
      d_buffer_count = q_buffer_count;
         if(q_sub_counter == COL_C)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PART;
               if(q_inputs >= MAX_C)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PART;
         end
      end
end
end  
    
always_comb begin
pointer = q_buffer_count-1; 
   if(q_buffer_count == 0)
      pointer = 0;
end      
    
assign finished = (finish_process)&(~sample_type);//another update
assign write_out = d_write;

always_comb begin
   place_memory = 0;
   if(d_write) begin
      place_memory = full_result;
      if(q_sub_counter == COL_C)begin
         place_memory[16*P_BIT_WIDTH-1:(16-PART)*P_BIT_WIDTH] = q_buffer;
         place_memory[(16-PART)*P_BIT_WIDTH-1:0] = 0;
      end
   end
end

always_comb begin
   full_result = 0;
   case(pointer)
   'd23:begin
       full_result = q_buffer[24*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd22:begin
       full_result = q_buffer[23*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd21:begin
       full_result = q_buffer[22*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd20:begin
       full_result = q_buffer[21*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd19:begin
       full_result = q_buffer[20*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd18:begin
       full_result = q_buffer[19*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd17:begin
       full_result = q_buffer[18*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd16:begin
       full_result = q_buffer[17*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd15:begin
       full_result = q_buffer[16*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   default:begin
      full_result = 0;
   end
   endcase
end    
    
endmodule
