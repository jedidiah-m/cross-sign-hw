`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module benchmark();


int unsigned seed = 32'h00000001;
integer clocks = 0;
logic clk;
logic rst;
logic shift_seed_sk;
logic [w-1:0] data_system;
logic shift_seed_lambda;
logic [w-1:0] seed_lambda;
logic shift_salt;
logic [w-1:0] salt;
logic occupied;
logic shift_message;
logic [w-1:0]message;
logic request_signature;
logic module_response;
logic [w-1:0]valid_signature_out;

integer file_handle;

sign_top dut(
    .clk                (clk),
    .rst                (rst),
    .shift_seed_sk      (shift_seed_sk),
    .data_system        (data_system),
    .shift_seed_lambda  (shift_seed_lambda),
    .seed_lambda        (seed_lambda),
    .shift_salt         (shift_salt),
    .salt               (salt),
    .shift_message      (shift_message),
    .message            (message),
    .request_signature  (request_signature),
    .module_response    (module_response),
    .valid_signature_out(valid_signature_out),
    .occupied           (occupied)
    );
   
initial clk = 1;
always #4 clk = ~clk;


initial begin
  file_handle = $fopen("C:/Users/xhuli/CROSS_sign/CROSS_sign.srcs/sim_1/imports/new/level_1.txt", "w"); //change the address
        if (file_handle == 0) begin
            $display("ERROR: Could not open file for writing.");
            $finish;
        end
  $display("File opened successfully.");
  repeat(100)begin
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   rst <= 1;
   shift_seed_sk <= 0;
   data_system <= 0;
   shift_seed_lambda <= 0;
   seed_lambda <= 0;
   shift_salt <= 0;
   salt <= 0;
   shift_message <= 0;
   message <= 0;
   request_signature <= 0;
   
   repeat(20)@(posedge clk);
   rst <= 0;
   repeat(2) @(posedge clk);
   
   for(int i = 0; i <((2*LAMBDA)/w); i++)begin
      shift_seed_sk <= 1;
      data_system <= {$urandom(seed),$urandom(seed+1)};////
      @(posedge clk);
      seed = seed + 2;
   end
   
   shift_seed_sk <= 0;
   data_system <= 0;
   @(posedge clk);
   
   @(negedge occupied)
   @(posedge clk);
   
   for(int i = 0; i <((LAMBDA)/w); i++)begin
      shift_seed_lambda <= 1;
      seed_lambda <= {$urandom(seed),$urandom(seed+1)};////
      @(posedge clk);
      seed = seed + 2;
   end
   
   shift_seed_lambda <= 0;
   seed_lambda <= 0;
   @(posedge clk);
   
   for(int i = 0; i <((2*LAMBDA)/w); i++)begin
      shift_salt <= 1;
      salt <= {$urandom(seed),$urandom(seed+1)};////
      @(posedge clk);
      seed = seed + 2;
   end
   
      shift_salt <= 0;
      salt <= 0;
      @(posedge clk);
   
   @(negedge occupied)
   @(posedge clk);
   
   shift_message <= 1;
   message <= 64'h3D;
   @(posedge clk);
   
   shift_message <= 0;
   message <= 0;
   @(posedge clk);
   
   for(int i = 0; i < 7; i++)begin
      shift_message <= 1;
      message <= {$urandom(seed),$urandom(seed+1)};////
      @(posedge clk);
      seed = seed + 2;
   end
   
   message <= 64'h556AC80080000000;
   @(posedge clk);
   seed = seed + 2;
   
   shift_message <= 0;
   message <= 0;
   
   @(negedge occupied);
   @(posedge clk);
   $fwrite(file_handle, "%0d\n",  clocks);
   repeat(20)@(posedge clk);
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   end
   $fclose(file_handle);
   $display("File closed. Simulation finished.");
   $finish;
end

always begin
@(negedge clk)
   if(rst)begin
      clocks = 0;
   end else if(occupied)begin
      clocks = clocks + 8;
   end
end

endmodule

