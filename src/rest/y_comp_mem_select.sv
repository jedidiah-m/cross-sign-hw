`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module y_comp_mem_select(
    input  logic clka,
    input  logic [13:0] addra,
    input  logic [w-1:0] dina,
    input  logic wea,
    output logic [w-1:0] douta
    );
    
generate
   if (SECURITY_LVL == 1) begin : level_1
      y_comp_1 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta)
      );
   end else if (SECURITY_LVL == 3) begin : level_3
      y_comp_3 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta) 
      );
   end else if (SECURITY_LVL == 5) begin : level_5
      y_comp_5 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta) 
      );
   end
endgenerate
    
endmodule