`timescale 1ns / 1ps
 
import keccak_pkg::*;
import rsdp_pkg::*;
                                                 
module first_challenge_generator(
    input  logic clk,
    input  logic rst,
    input  logic valid_o,
    input  logic [w-1:0]data_in,
    input  logic finish_op,
    input  logic ready_o_system,
    output logic ready_o,
    output logic finish,
    output logic start_op,
    output logic [(4*P_BIT_WIDTH)-1:0]data_out
    );
    
logic [P_BIT_WIDTH-1:0] data_out_inter;
    
ch1_buffer buffer(
   .clk     (clk),
   .reset   (rst),
   .valid_o (valid_o),
   .data_in (data_in),
   .finished(finish),
   .shift   (shift),
   .data_out(data_out_inter)
    );
    
first_challenge_sampler sampler(
   .clk      (clk),
   .rst      (rst),
   .data_in  (data_out_inter),
   .finish_op(finish_op),
   .valid_o  (valid_o),
    
   .data_out (data_out),
   .start_op (start_op),
   .interrupt(interrupt),
   .shift    (shift),
   .finish   (finish)
    );
    
assign ready_o = ready_o_system & (~interrupt);
    
endmodule