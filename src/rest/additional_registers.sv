`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*; 

module additional_registers(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] port_1,
    input  logic [w-1:0] port_2,
    input  logic [w-1:0] port_3,
    input  logic shift_1,
    input  logic shift_2,
    input  logic shift_3,
    input  logic rotate_a,
    input  logic rotate_b,
    output logic [w-1:0] output_a,
    output logic [w-1:0] output_b
    );
    
logic [w-1:0] port_a;
logic [1:0] shift_a;

assign shift_a = {shift_1,shift_2};

always_comb begin
   port_a = 64'h0;
   case(shift_a)
      2'b10   : port_a = port_1;
      2'b01   : port_a = port_2;
      default : port_a = 64'h0;
   endcase
end

pad_generator #(
     .DEPTH(4*(LAMBDA/w))
)storage_a(
   .clk      (clk),
   .reset    (rst),
   .shift    (shift_1||shift_2),
   .rotate   (rotate_a),
   .data_in  (port_a),
   .data_out (output_a)
);

pad_generator #(
     .DEPTH(4*(LAMBDA/w))
)storage_b(
   .clk      (clk),
   .reset    (rst),
   .shift    (shift_3),
   .rotate   (rotate_b),
   .data_in  (port_3),
   .data_out (output_b)
);
    
endmodule