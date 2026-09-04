`timescale 1ns / 1ps

import rsdp_pkg::*;

module memory_e_bar_top(
    input  logic clk,
    input  logic rst,
    input  logic vector_pulse,
    input  logic matrix_pulse,
    input  logic write_ebar,
    input  logic write_vt,
    input  logic [16*Z_BIT_WIDTH-1:0] outer_place_ebar,
    input  logic finished_vt,
    output logic mode,
    output logic shift_single,
    output logic [16*Z_BIT_WIDTH-1:0] array_add,
    output logic [Z_BIT_WIDTH-1:0] e_bar_mul
    );
    
logic q_s,d_s;
logic [16*Z_BIT_WIDTH-1:0] place_ebar;

always_ff @(posedge clk) begin
   if(rst)begin
      q_s <= 0;
   end else begin
      q_s <= d_s;
   end
end

always_comb begin 
   d_s = q_s;
   if(vector_pulse)begin
      d_s = 1;
   end else if(matrix_pulse) begin
      d_s = 0;
   end
end

always_comb begin
   place_ebar = outer_place_ebar;
   if(q_s)
      place_ebar = array_add;
end
   
memory_e_bar #(
    .DATA_WIDTH(Z_BIT_WIDTH)
) meb(
    .clk          (clk),
    .rst          (rst),
    .write_ebar   (write_ebar),
    .write_vt     (write_vt),
    .place_ebar   (place_ebar),
    .finished_vt  (finished_vt),
    .mode         (mode),
    .shift_single (shift_single),
    .array_add    (array_add),
    .e_bar_mul    (e_bar_mul)
    );
   
endmodule
