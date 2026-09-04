`timescale 1ns / 1ps

import keccak_pkg::*;

module tb_input_prep();

logic clk;
logic rst;
logic s_pulse;
logic v_pulse;
logic y_pulse;
logic salt_pulse;
logic suffix_pulse;
logic valid_s;
logic valid_v;
logic valid_y;
logic valid_salt;
logic valid_suffix;
logic end_pulse;
logic [w-1:0] data_out;
logic valid_out;

logic [12*w-1:0] synd,vec;
logic [8*w-1:0] slt;
logic [w-1:0] coeff;

input_preparation dut(
    .clk          (clk),
    .rst          (rst),
    .s_vector     (synd[12*w-1 -: w]),
    .v_vector     (vec[12*w-1 -: w]),
    .y_vector     (0),
    .salt         (slt[8*w-1 -: w]),
    .suffix       (coeff),
    .s_pulse      (s_pulse),
    .v_pulse      (v_pulse),
    .y_pulse      (y_pulse),
    .salt_pulse   (salt_pulse),
    .suffix_pulse (suffix_pulse),
    .valid_s      (valid_s),
    .valid_v      (valid_v),
    .valid_y      (valid_y),
    .valid_salt   (valid_salt),
    .valid_suffix (valid_suffix),
    .end_pulse    (end_pulse),
    .data_out     (data_out),
    .valid_out    (valid_out)
    );

initial clk = 1;
always #5 clk = ~clk;

always begin
         @(posedge valid_s);
         @(posedge clk);
         synd = {synd,64'h0};
end

always begin
         @(posedge valid_v);
         @(posedge clk);
         vec = {vec,64'h0};
end

always begin
         @(posedge valid_salt);
         @(posedge clk);
         slt = {slt,64'h0};
end

always begin
         @(posedge valid_suffix);
         @(posedge clk);
         coeff = {coeff,64'h0};
end

initial begin
   synd  = 768'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffaa00000000000000;
   vec   = 768'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffbbbbbbbbbbbbbb00;
   slt   = 512'hffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
   coeff =  64'h3333000000000000;
end

initial begin
    rst          <= 1;
    s_pulse      <= 0;
    v_pulse      <= 0;
    y_pulse      <= 0;
    salt_pulse   <= 0;
    suffix_pulse <= 0;
    
   repeat(20)@(posedge clk);
   rst <= 0;
   repeat(2) @(posedge clk);
   
   s_pulse <= 1;
   @(posedge clk);
   s_pulse <= 0;
    
   wait(end_pulse)
   @(posedge clk);
   v_pulse <= 1;
   @(posedge clk);
   v_pulse <= 0;
   
   wait(end_pulse)
   @(posedge clk);
   salt_pulse <= 1;
   @(posedge clk);
   salt_pulse <= 0;
   
   wait(end_pulse)
   @(posedge clk);
   suffix_pulse <= 1;
   @(posedge clk);
   suffix_pulse <= 0;
   repeat(20) @(posedge clk);
end

endmodule
