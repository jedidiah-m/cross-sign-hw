`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module compress_assist(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0] s_vector,
    input  logic [w-1:0] v_vector,
    input  logic [w-1:0] y_vector,
    input  logic [w-1:0] salt,
    input  logic [w-1:0] suffix,
    input  logic [w-1:0] dig_chall,//
//    input  logic [w-1:0] suffix2,//
    input  logic s_pulse,
    input  logic v_pulse,
    input  logic y_pulse,
    input  logic salt_pulse,
    input  logic suffix_pulse,
    input  logic dig_chall_pulse,//
    input  logic suffix2_pulse,//
    output logic flush,
    output logic valid_s,
    output logic valid_v,
    output logic valid_y,
    output logic valid_salt,
    output logic valid_suffix,
    output logic valid_dig_chall,//
    output logic valid_suffix2,//
    output logic end_pulse,
    output logic [2:0] bytes,
    output logic [w-1:0] data
    );
    

localparam int S_SHIFTS = (SECURITY_LVL == 1) ?  6:
                          (SECURITY_LVL == 3) ?  9:
                          (SECURITY_LVL == 5) ? 12:
                                                 0;
localparam int S_BYTES =  (SECURITY_LVL == 1) ? 5:
                          (SECURITY_LVL == 3) ? 3:
                          (SECURITY_LVL == 5) ? 1:
                                                0;  
                                                
localparam int V_SHIFTS = (SECURITY_LVL == 1) ?  6:
                          (SECURITY_LVL == 3) ?  9:
                          (SECURITY_LVL == 5) ? 12:
                                                 0;     
localparam int V_BYTES =  (SECURITY_LVL == 1) ? 0:
                          (SECURITY_LVL == 3) ? 7:
                          (SECURITY_LVL == 5) ? 7:
                                                0;    
                                                
localparam int Y_SHIFTS = (SECURITY_LVL == 1) ? 14:
                          (SECURITY_LVL == 3) ? 21:
                          (SECURITY_LVL == 5) ? 28:
                                                 0;     
localparam int Y_BYTES =  (SECURITY_LVL == 1) ? 0:
                          (SECURITY_LVL == 3) ? 4:
                          (SECURITY_LVL == 5) ? 4:
                                                0;   

logic [5:0] d_count,q_count;
logic [6:0] pulse_group;
logic [2:0] d_sel,q_sel;
logic [6:0] q_max_count,d_max_count;
logic pulse,proc,d_p,q_p;

assign pulse_group = {s_pulse,v_pulse,y_pulse,salt_pulse,suffix_pulse,dig_chall_pulse,suffix2_pulse};
assign pulse = s_pulse|v_pulse|y_pulse|salt_pulse|suffix_pulse|dig_chall_pulse|suffix2_pulse;

always_ff @(posedge clk)begin
   if(rst)begin 
      q_count     <= 0; 
      q_max_count <= 0;
      q_sel       <= 0;
      q_p         <= 0;
   end else begin 
      q_count     <= d_count; 
      q_max_count <= d_max_count;
      q_sel       <= d_sel;
      q_p         <= d_p;
   end
end                         
        
always_comb begin
   d_max_count = q_max_count;
   d_count = q_count;
   d_sel = q_sel;
   if((pulse)&&(!proc))begin
      d_count = 0;
      case(pulse_group)
         7'b1000000 : begin
            d_max_count = 2*S_SHIFTS - 1;
            d_sel       = 1; 
         end
         7'b0100000 : begin
            d_max_count = 2*V_SHIFTS - 1;
            d_sel       = 2;
         end
         7'b0010000 : begin
            d_max_count = 2*Y_SHIFTS - 1;
            d_sel       = 3;
         end
         7'b0001000 : begin
            d_max_count = (4*(LAMBDA/w)) - 1;
            d_sel       = 4;
         end
         7'b0000100 : begin
            d_max_count = 1;
            d_sel       = 5;
         end
         7'b0000010 : begin
            d_max_count = (4*(LAMBDA/w)) - 1;
            d_sel       = 6;
         end
         7'b0000001 : begin
            d_max_count = 1;
            d_sel       = 7;
         end
         default  : begin
            d_max_count = 0;
            d_sel       = 0;
         end
      endcase
   end else if((q_count < q_max_count))begin
      d_count = q_count + 1;
   end
end    

assign proc = (q_count < q_max_count);
assign d_p = proc;
assign end_pulse = (~d_p) & (q_p);
assign flush = ((end_pulse)&&((q_sel == 5)||(q_sel == 7)));

assign valid_s         = ((proc)&&(q_count[0] == 0)&&(q_sel == 1));
assign valid_v         = ((proc)&&(q_count[0] == 0)&&(q_sel == 2));
assign valid_y         = ((proc)&&(q_count[0] == 0)&&(q_sel == 3));
assign valid_salt      = ((proc)&&(q_count[0] == 0)&&(q_sel == 4));
assign valid_suffix    = ((proc)&&(q_count[0] == 0)&&(q_sel == 5));
assign valid_dig_chall = ((proc)&&(q_count[0] == 0)&&(q_sel == 6));
assign valid_suffix2   = ((proc)&&(q_count[0] == 0)&&(q_sel == 7));

always_comb begin
   data = 0;
   case(q_sel)
      1: data = s_vector;
      2: data = v_vector;
      3: data = y_vector;
      4: data = salt;
      5: data = suffix;
      6: data = dig_chall;
      7: data = EndianSwitcher#(w)::switch(HASH_CONST);
      default: data = 0;
   endcase 
end      
 
always_comb begin
   bytes = 0;
   if((q_count == q_max_count - 1))begin
      case(q_sel)
         1: bytes = S_BYTES;
         2: bytes = V_BYTES;
         3: bytes = Y_BYTES;
         4: bytes = 0;
         5: bytes = 2;
         6: bytes = 0;
         7: bytes = 2;
         default: bytes = 0;
      endcase
   end
end
                                                
endmodule
