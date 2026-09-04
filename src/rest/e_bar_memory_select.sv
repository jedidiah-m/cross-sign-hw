`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module e_bar_memory_select(
    input  logic clka,
    input  logic [12:0] addra,
    input  logic [16*Z_BIT_WIDTH-1:0] dina,
    input  logic wea,
    output logic [16*Z_BIT_WIDTH-1:0] douta
    );
    
generate
   if (SECURITY_LVL == 1) begin : level_1
      e_bar_1 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta)
      );
   end else if (SECURITY_LVL == 3) begin : level_3
      e_bar_3 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta) 
      );
   end else if (SECURITY_LVL == 5) begin : level_5
      e_bar_5 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta) 
      );
   end
endgenerate
    
endmodule