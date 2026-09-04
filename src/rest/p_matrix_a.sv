`timescale 1ns / 1ps

import rsdp_pkg::*;

module p_matrix_a(
    input  logic mode,
    input  logic [P_BIT_WIDTH-1:0] u_mul,
    input  logic [P_BIT_WIDTH-1:0] u_add,
    input  logic [P_BIT_WIDTH-1:0] v_t,
    input  logic [P_BIT_WIDTH-1:0] q_mem,
    output logic [P_BIT_WIDTH-1:0] out
    );
logic [2*P_BIT_WIDTH-1:0] prod,op1,op2,res;   

assign prod = v_t * u_mul;
assign op1  = prod + q_mem;
assign op2  = q_mem + u_add;

always_comb begin
   res = op1;
   if(mode)
      res = op2;
end
   
modulo_unit md(
    .data_i (res),
    .data_o (out)
); 
    
endmodule

