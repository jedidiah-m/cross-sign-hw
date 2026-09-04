`timescale 1ns / 1ps

import rsdp_pkg::*;

module subz_unit(
    input  logic [Z_BIT_WIDTH-1:0] data_i1,
    input  logic [Z_BIT_WIDTH-1:0] data_i2,
    output logic [Z_BIT_WIDTH-1:0] data_o
    );
    
    logic [Z_BIT_WIDTH-1:0] data_inter;
    
    assign data_inter = 3'b111 - data_i2;
    
    always_comb begin
    data_o = data_i1 - data_i2;
       if ( data_i2 > data_i1 ) data_o = data_i1 + data_inter; 
    end
    
endmodule
