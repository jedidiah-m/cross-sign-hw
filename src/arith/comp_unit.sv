`timescale 1ns / 1ps

import keccak_pkg::*;

module comp_unit(
    input  logic clk,
    input  logic reset,
    input  logic shift_in,
    input  logic [2:0] bytes,
    input  logic [w-1:0] data_in,
    input  logic flush,
    output logic [w-1:0] data_out,
    output logic valid_out
    );
    
logic [2*w-1:0] d_buffer, q_buffer;
logic [4:0] d_counter, q_counter, pointer, interm;
logic d_f,q_f;

always_ff @(posedge clk)begin
   if(reset)begin
      q_buffer  <= 0;  
      q_counter <= 0; 
      q_f       <= 0;
   end else begin
      q_buffer  <= d_buffer;
      q_counter <= d_counter;
      q_f       <= d_f;
   end
end
   
always_comb begin
pointer = q_counter - 1;
   if(q_counter == 0)
      pointer = 0;
end
  
always_comb begin
d_counter = interm;
   if((!shift_in)&&(q_f))begin
      d_counter = 0;
   end
   if((shift_in)&&(!flush)&&(!q_f))begin
      case(bytes)
         3'b000 : d_counter = interm + 8;
         3'b001 : d_counter = interm + 1;
         3'b010 : d_counter = interm + 2;
         3'b011 : d_counter = interm + 3;
         3'b100 : d_counter = interm + 4;
         3'b101 : d_counter = interm + 5;
         3'b110 : d_counter = interm + 6;
         3'b111 : d_counter = interm + 7;
         default  d_counter = interm;
      endcase
   end
end

always_comb begin
interm = q_counter;
   if(q_counter > 5'd7)
      interm = q_counter - 8;
end
   
always_comb begin
valid_out = 0;
   if((q_counter > 5'd7)||(q_f))
      valid_out = 1;
end 

assign d_f = (q_counter == 0) ? 0 : flush;

always_comb begin
d_buffer  = q_buffer;
   if((shift_in)&&(!flush)&&(!q_f))begin
      case(bytes)
         3'b000 : d_buffer  = {q_buffer[2*w-1-64:0],data_in[63:0 ]};
         3'b001 : d_buffer  = {q_buffer[2*w-1-8 :0],data_in[63:56]};
         3'b010 : d_buffer  = {q_buffer[2*w-1-16:0],data_in[63:48]};
         3'b011 : d_buffer  = {q_buffer[2*w-1-24:0],data_in[63:40]};
         3'b100 : d_buffer  = {q_buffer[2*w-1-32:0],data_in[63:32]};
         3'b101 : d_buffer  = {q_buffer[2*w-1-40:0],data_in[63:24]};
         3'b110 : d_buffer  = {q_buffer[2*w-1-48:0],data_in[63:16]};
         3'b111 : d_buffer  = {q_buffer[2*w-1-56:0],data_in[63:8 ]};
         default d_buffer  = q_buffer;
      endcase
   end
end

always_comb begin
data_out = 0;
   if(valid_out)begin
      case(pointer)
         5'b00000 : if(q_f) data_out = {q_buffer[8 :0],56'b0};
         5'b00001 : if(q_f) data_out = {q_buffer[16:0],48'b0};
         5'b00010 : if(q_f) data_out = {q_buffer[24:0],40'b0};
         5'b00011 : if(q_f) data_out = {q_buffer[32:0],32'b0};
         5'b00100 : if(q_f) data_out = {q_buffer[40:0],24'b0};
         5'b00101 : if(q_f) data_out = {q_buffer[48:0],16'b0};
         5'b00110 : if(q_f) data_out = {q_buffer[56:0], 8'b0};
         5'b00111 : data_out = q_buffer[63  -: w];
         5'b01000 : data_out = q_buffer[71  -: w];
         5'b01001 : data_out = q_buffer[79  -: w];
         5'b01010 : data_out = q_buffer[87  -: w];
         5'b01011 : data_out = q_buffer[95  -: w];
         5'b01100 : data_out = q_buffer[103 -: w];
         5'b01101 : data_out = q_buffer[111 -: w];
         5'b01110 : data_out = q_buffer[119 -: w];
         5'b01111 : data_out = q_buffer[127 -: w];
         default data_out = 0;
      endcase
   end
end

   
endmodule
