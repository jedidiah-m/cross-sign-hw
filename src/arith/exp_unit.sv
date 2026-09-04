`timescale 1ns / 1ps

import rsdp_pkg::*;

module exp_unit(
    input  logic [Z_BIT_WIDTH-1:0] data_i,
    output logic [P_BIT_WIDTH-1:0] data_o
    );
    
    always_comb begin
       case(data_i)
       3'b000 : data_o = 7'b0000001;
       3'b001 : data_o = 7'b0000010;
       3'b010 : data_o = 7'b0000100;
       3'b011 : data_o = 7'b0001000;
       3'b100 : data_o = 7'b0010000;
       3'b101 : data_o = 7'b0100000;
       3'b110 : data_o = 7'b1000000;
       default  data_o = 7'b0000000;
       endcase
    end
    
endmodule
