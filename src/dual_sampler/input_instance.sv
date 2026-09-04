`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module input_instance(
    input  logic clk,
    input  logic reset,
    input  logic [w-1:0] data_in_module,
    input  logic valid_in_module,
    input  logic interrupt_in_module,
    input  logic sample_type,
    input  logic clr,
    output logic [w-1:0] data_out_module,
    output logic valid_out_module,
    output logic interrupt_out_module
    );
    
logic shift_in;
logic [2:0] bytes;
logic [w-1:0] data_in;
logic flush;
logic [w-1:0] data_out;
logic valid_out;
logic [7:0] q_count,d_count;
logic [1:0] q_blocks,d_blocks;
logic q_int, d_int;
logic q_interrupt, d_interrupt;
logic q_clr, d_clr;
logic freeze,real_valid_in;
    
always_ff @(posedge clk)begin
   if(reset)begin
      q_blocks  <= 0;  
      q_count   <= 0; 
      q_int     <= 0;
      q_clr     <= 0;
      q_interrupt <= 0;
   end else begin
      q_blocks  <= d_blocks;
      q_count   <= d_count;
      q_int     <= d_int;
      q_clr     <= d_clr;
      q_interrupt <= d_interrupt;
   end
end
    
comp_unit cu(
   .clk      (clk),
   .reset    (reset),
   .shift_in (shift_in),
   .bytes    (bytes),
   .data_in  (data_in),
   .flush    (flush),
   .data_out (data_out),
   .valid_out(valid_out)
    );
    
assign flush = clr;
assign d_clr = clr;
assign valid_out_module = (~q_clr)&(valid_out);
assign data_out_module = data_out;

assign d_int = interrupt_in_module;

always_comb begin
   bytes = 0;
   data_in = data_in_module;
   if(freeze)begin
      bytes = BUFF_FZ_PART;
      data_in[w-1 -: BUFF_FZ_PART*8] = data_in_module[BUFF_FZ_PART*8-1 : 0];
      data_in[w-BUFF_FZ_PART*8-1 : 0] = '0;
   end
end
    
always_comb begin
   d_count = q_count;
   if(valid_in_module)begin
      d_count = q_count + 1;
   end 
   else if(clr)begin
      d_count = 0;
   end
end  

assign real_valid_in = ((sample_type)&&(q_count <= BUFF_SIZE_FZ)) ? 0 : valid_in_module;

assign freeze = (q_count == BUFF_SIZE_FZ) ? 1 : 0;
assign shift_in = real_valid_in | freeze;

always_comb begin
   d_blocks = q_blocks;
   d_interrupt = q_interrupt;
   if((!d_int)&&(q_int))begin
      d_interrupt = 0;
   end
   if(real_valid_in)begin
      d_blocks = q_blocks + 1;
      if(q_blocks == 2)begin
         d_blocks = 0;
         d_interrupt = 1;
      end
   end
end
    
assign interrupt_out_module = q_interrupt;  
    
endmodule
