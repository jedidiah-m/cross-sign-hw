`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module memory_s(
    input  logic clk,
    input  logic rst,
    input  logic write_vt,
    input  logic mde,
    input  logic access,
    input  logic [16*P_BIT_WIDTH-1:0] in_memory,
    output logic [16*P_BIT_WIDTH-1:0] out_memory,
    output logic [w-1:0] public_key,
    output logic ended
    );
    
localparam int PACK = (N_VEC - K_VEC) / 16;
    
logic [w-1:0] first;   
logic [16*P_BIT_WIDTH-1:0] q_mem[0:PACK]; 
logic [16*P_BIT_WIDTH-1:0] d_mem[0:PACK];
logic [5:0] q_address, d_address;
logic q_end,d_end;

function logic [16*P_BIT_WIDTH-1:0] endian_bit_switch(input logic [16*P_BIT_WIDTH-1:0] x);
      logic [16*P_BIT_WIDTH-1:0] result;
        for (int j = 0; j < 16; j++) begin
           for (int i = 0; i < P_BIT_WIDTH; i++) begin
              result[j*P_BIT_WIDTH + i] = x[j*P_BIT_WIDTH + P_BIT_WIDTH - 1 - i];
           end
        end
      return result;
endfunction

function logic [w-1:0] swtc(input logic [w-1:0] x);
      logic [w-1:0] result;
        for (int j = 0; j < 8; j++) begin
           for (int i = 0; i < 8; i++) begin
              result[j*8 + i] = x[j*8 + 7 - i];
           end
        end
      return result;
endfunction

always_ff @(posedge clk) begin
   if(rst)begin
      q_mem <= '{default: '0};
      q_address <= 0;
      q_end <= 0;
   end else begin
      q_mem <= d_mem;
      q_address <= d_address;
      q_end <= d_end;
   end
end

always_comb begin
   d_address = q_address;
   if(write_vt || mde)begin
      d_address = q_address + 1;
      if(q_address == PACK)
         d_address = 0;
   end
end

always_comb begin
   d_mem = q_mem;
   if((write_vt || mde)&&(q_address <= PACK))begin
      d_mem[q_address] = in_memory;
      if(mde)
         d_mem[q_address] = endian_bit_switch(in_memory);
   end
   if(access)begin
      d_mem[PACK] = {q_mem[PACK][16*P_BIT_WIDTH - w - 1 : 0],64'b0}; //q_mem[0][16*P_BIT_WIDTH-1 -: w]
      for(int i = 0; i < PACK; i++) begin
         d_mem[i] = {q_mem[i][16*P_BIT_WIDTH - w - 1 : 0],q_mem[i+1][16*P_BIT_WIDTH - 1 -: w]};
      end
   end
end

always_comb begin
   out_memory = 0;
   if(q_address <= PACK)
      out_memory = q_mem[q_address];
end

assign d_end = mde;
assign ended = (!d_end)&(q_end);
assign first = q_mem[0][16*P_BIT_WIDTH-1 -: w];
assign public_key = swtc(first);

endmodule

