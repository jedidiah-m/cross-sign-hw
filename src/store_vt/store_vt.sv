`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

localparam int       MAX_COUNT = (N_VEC - K_VEC) * K_VEC;
localparam int         PARTIAL = (N_VEC - K_VEC) % 16;
localparam int       COL_COUNT = (N_VEC - K_VEC) / 16;

module store_vt(
    input  logic clk,
    input  logic reset,
    input  logic valid_parallel,
    input  logic valid_serial,
    input  logic [P_BIT_WIDTH-1:0] data_serial,
    input  logic [9*P_BIT_WIDTH-1:0] data_parallel,
    output logic finished,
    output logic write_out,
    output logic [16*P_BIT_WIDTH-1:0] place_memory
    );
    
logic [30*P_BIT_WIDTH-1:0] d_buffer, q_buffer;
logic [$clog2(MAX_COUNT)-1:0] d_inputs,q_inputs;
logic [5:0] d_buffer_count,q_buffer_count,pointer;
logic [3:0] q_sub_counter,d_sub_counter;
logic [PARTIAL*P_BIT_WIDTH-1:0] partial_result;
logic [16*P_BIT_WIDTH-1:0] full_result;
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
      d_buffer = {q_buffer[(30-1)*P_BIT_WIDTH-1:0],data_serial};
      d_buffer_count = q_buffer_count + 1;
      if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_COUNT)begin
               d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 1;
         if(q_sub_counter == COL_COUNT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL;
               if(q_inputs >= MAX_COUNT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL + 1;
         end
      end
   end
   
   if((!valid_serial) && (valid_parallel))begin
      d_buffer = {q_buffer[(30-9)*P_BIT_WIDTH-1:0],data_parallel};
      d_buffer_count = q_buffer_count + 9;
     if(q_buffer_count >= 'b10000)begin
         d_write = 1;
         d_sub_counter = q_sub_counter + 1;
            d_inputs = q_inputs + 'b10000;
            if(q_inputs >= MAX_COUNT)begin
                  d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000 + 9;
         if(q_sub_counter == COL_COUNT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL;
               if(q_inputs >= MAX_COUNT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL + 9;
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
            if(q_inputs >= MAX_COUNT)begin
                  d_inputs = 0;
            end
         d_buffer_count = q_buffer_count - 'b10000;
         if(q_sub_counter == COL_COUNT)begin
            d_write = 1;
            d_sub_counter = 0;
               d_inputs = q_inputs + PARTIAL;
               if(q_inputs >= MAX_COUNT)begin
                  d_inputs = 0;
               end
            d_buffer_count = q_buffer_count - PARTIAL;
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
    
always_comb begin
d_finished = q_finished; 
   if(q_inputs == MAX_COUNT)
      d_finished = 1;
   if(q_inputs == 0)
      d_finished = 0;
end  

assign fin = d_finished & (!q_finished);
assign finished = fin;
assign write_out = d_write;

always_comb begin
   place_memory = 0;
   if(d_write) begin
      place_memory = full_result;
      if(q_sub_counter == COL_COUNT)begin
         place_memory[16*P_BIT_WIDTH-1:(16-PARTIAL)*P_BIT_WIDTH] = partial_result;
         place_memory[(16-PARTIAL)*P_BIT_WIDTH-1:0] = 0;
      end
   end
end

always_comb begin
   partial_result = 0;
   full_result = 0;
   case(pointer)
   'd29:begin
       partial_result = q_buffer[30*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[30*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
    end
   'd28:begin
       partial_result = q_buffer[29*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[29*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
    end
   'd27:begin
       partial_result = q_buffer[28*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[28*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
    end
   'd26:begin
       partial_result = q_buffer[27*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[27*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd25:begin
       partial_result = q_buffer[26*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[26*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end 
   'd24:begin
       partial_result = q_buffer[25*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[25*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end 
   'd23:begin
       partial_result = q_buffer[24*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[24*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd22:begin
       partial_result = q_buffer[23*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[23*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd21:begin
       partial_result = q_buffer[22*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[22*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd20:begin
       partial_result = q_buffer[21*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[21*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd19:begin
       partial_result = q_buffer[20*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[20*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd18:begin
       partial_result = q_buffer[19*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[19*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd17:begin
       partial_result = q_buffer[18*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[18*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd16:begin
       partial_result = q_buffer[17*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[17*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   'd15:begin
       partial_result = q_buffer[16*P_BIT_WIDTH-1 -: PARTIAL*P_BIT_WIDTH];
       full_result = q_buffer[16*P_BIT_WIDTH-1 -: 16*P_BIT_WIDTH];
   end
   default:begin
      partial_result = 0;
      full_result = 0;
   end
   endcase
end    


endmodule
