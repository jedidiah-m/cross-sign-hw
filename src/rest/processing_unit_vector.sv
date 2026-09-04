`timescale 1ns / 1ps

import rsdp_pkg::*;

module processing_unit_vector(
    input  logic [16*Z_BIT_WIDTH-1:0] e_bar_prime,
//    input  logic [16*Z_BIT_WIDTH-1:0] e_bar,
    input  logic [P_BIT_WIDTH-1:0] chall_1,
    input  logic [16*P_BIT_WIDTH-1:0] u_prime,
    output logic [16*P_BIT_WIDTH-1:0] y
//    output logic [16*Z_BIT_WIDTH-1:0] v_bar
    );
    
genvar i;
    
for (i = 0; i < 16; i = i + 1) begin:processor
   p_vector p_vec(
      .e_bar_prime (e_bar_prime[(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH]),
      .chall_1     (chall_1),
      .u_prime     (u_prime[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH]),
      .y           (y[(16-i)*P_BIT_WIDTH-1 -: P_BIT_WIDTH])
   );
end 

//for (i = 0; i < 16; i = i + 1) begin:subtractors
//   subz_unit subz(
//      .data_i1 (e_bar      [(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH]),
//      .data_i2 (e_bar_prime[(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH]),
//      .data_o  (v_bar      [(16-i)*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH])
//   );
//end

endmodule
