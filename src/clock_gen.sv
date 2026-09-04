`timescale 1ns / 1ps

module clock_gen(
    input  logic clk_in,
    input  logic rst,
    output logic clk_out
    );
    
    clock_wrapper clk_wp(
       .clk_out1(clk_out),
       .reset   (rst),
       .locked  (),
       .clk_in1 (clk_in)
    );
    
endmodule