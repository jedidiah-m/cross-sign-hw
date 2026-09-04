`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module test_expand_keys();

logic clk;
logic rst;
logic shift_seed_sk;
logic [w-1:0] data_system;
logic [w-1 : 0]somevalue [0:19];
logic shift_seed_lambda;
logic [w-1:0] seed_lambda;
logic shift_salt;
logic [w-1:0] salt;
logic occupied;
//logic write_sig;
//logic [w-1:0] signature;
logic shift_message;
logic [w-1:0]message;
logic request_signature;
logic module_response;
logic [w-1:0]valid_signature_out;

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
//    .write_sig         (write_sig),
//    .signature         (signature)
    );

initial begin
   somevalue[0]  = 'h7C9935A0B07694AA;
   somevalue[1]  = 'h0C6D10E4DB6B1ADD;
   somevalue[2]  = 'h2FD81A25CCB14803;
   somevalue[3]  = 'h2DCD739936737F2D;
   somevalue[4]  = 'hB505D7CFAD1B4974;
   somevalue[5]  = 'h99323C8686325E47;
   somevalue[6]  = 'h92F267AAFA3F87CA;
   somevalue[7]  = 'h60D01CB54F29202A;
   
   somevalue[8]  = 'hEB4A7C66EF4EBA2D;
   somevalue[9]  = 'hDB38C88D8BC706B1;
   somevalue[10] = 'hD639002198172A7B;
   somevalue[11] = 'h1942ECA8F6C001BA;
   
   somevalue[12] = 'hBC07C06D4B4F0F96;
   somevalue[13] = 'h1EDE468325F9BB2D;
   somevalue[14] = 'h055C5B62B347EDA8;
   somevalue[15] = 'h6AA016E134B3A07F;
   somevalue[16] = 'h37943FC434E309BC;
   somevalue[17] = 'h5A254D5B9E54964D;
   somevalue[18] = 'h85665E8863D7DECA;
   somevalue[19] = 'hBC9C59FBDDE5CF63;
end
   
initial clk = 1;
always #4 clk = ~clk;

initial begin
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
      data_system <= somevalue[i];
      @(posedge clk);
   end
   
   shift_seed_sk <= 0;
   data_system <= 0;
   @(posedge clk);
   
   @(negedge occupied)
   @(posedge clk);
   
   for(int i = 8; i <((LAMBDA)/w)+8; i++)begin
      shift_seed_lambda <= 1;
      seed_lambda <= somevalue[i];
      @(posedge clk);
   end
   
   shift_seed_lambda <= 0;
   seed_lambda <= 0;
   @(posedge clk);
   
   for(int i = 12; i <((2*LAMBDA)/w)+12; i++)begin
      shift_salt <= 1;
      salt <= somevalue[i];
      @(posedge clk);
   end
   
      shift_salt <= 0;
      salt <= 0;
      @(posedge clk);
   
   @(negedge occupied)
   @(posedge clk);
   
   shift_message <= 1;
   message <= 64'h23;
   @(posedge clk);
   
   shift_message <= 0;
   message <= 0;
   @(posedge clk);
//D81C4D8D734FCBFB 
//EADE3D3F8A039FAA
//2A2C9957E835AD55
//B22E75BF57BB556A
//C8 0080 00 00000000
   shift_message <= 1;
   message <= 64'hD81C4D8D734FCBFB;
   @(posedge clk);
   
   message <= 64'hEADE3D3F8A039FAA;
   @(posedge clk);
   
   message <= 64'h2A2C9957E835AD55;
   @(posedge clk);
   
   message <= 64'hB22E75BF57BB556A;
   @(posedge clk);
   
   message <= 64'hC800800000000000;
   @(posedge clk);
   
   shift_message <= 0;
   message <= 0;
   
   @(negedge occupied)
   repeat(50)@(posedge clk);
   
   for(int i = 0;i<SIG_SIZE;i++)begin
      request_signature <= 1;
      @(posedge clk);
   end
   request_signature <= 0;
   repeat(50)@(posedge clk);
   
   $finish;
end

endmodule
