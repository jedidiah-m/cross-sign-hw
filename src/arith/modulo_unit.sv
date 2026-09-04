`timescale 1ns / 1ps

import rsdp_pkg::*;

module modulo_unit(
    input logic [2*P_BIT_WIDTH-1:0] data_i,
    output logic [P_BIT_WIDTH-1:0] data_o
    );
    
    logic [P_BIT_WIDTH-1:0] s1lo, s2lo, s1hi;
    logic s2hi;
    logic [P_BIT_WIDTH:0] res1; 
    logic [P_BIT_WIDTH-1:0] res2;
    
    assign s1lo = data_i[P_BIT_WIDTH-1:0];
    assign s1hi = data_i[2*P_BIT_WIDTH-1:P_BIT_WIDTH];
    assign res1 = s1hi + s1lo;
    
    assign s2lo = res1[P_BIT_WIDTH-1:0];
    assign s2hi = res1[P_BIT_WIDTH];
    assign res2 = s2hi + s2lo;
    
    always_comb begin
       data_o = res2; 
       if(res2 == 7'b1111111) data_o = 0;
    end
    
endmodule
