`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sig_process_mem_select(
    input  logic clka,
    input  logic [14:0] addra,
    input  logic [w-1:0] dina,
    input  logic wea,
    output logic [w-1:0] douta,
    input  logic clkb,
    input  logic [14:0] addrb,
    input  logic [w-1:0] dinb,
    input  logic web,
    output logic [w-1:0] doutb
    );
 
generate
   if (SECURITY_LVL == 1) begin : level_1
      sig_process_1 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta),
         .clkb  (clkb),
         .web   (web),
         .addrb (addrb),
         .dinb  (dinb),
         .doutb (doutb)
      );
   end else if (SECURITY_LVL == 3) begin : level_3
      sig_process_3 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta),
         .clkb  (clkb),
         .web   (web),
         .addrb (addrb),
         .dinb  (dinb),
         .doutb (doutb)
      );
   end else if (SECURITY_LVL == 5) begin : level_5
      sig_process_5 memory_unit(
         .clka  (clka),
         .wea   (wea),
         .addra (addra),
         .dina  (dina),
         .douta (douta),
         .clkb  (clkb),
         .web   (web),
         .addrb (addrb),
         .dinb  (dinb),
         .doutb (doutb)
      );
   end
endgenerate   
    
endmodule
