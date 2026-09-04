`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module e_bar_u_prime_sampler(
    input  logic clk,
    input  logic rst,
    input  logic interrupt,
    input  logic [7:0] bit_counter,
    //input  logic [Z_BIT_WIDTH-1:0] single_fz,
    input  logic [3*Z_BIT_WIDTH-1:0] parallel_fz,
    //input  logic [P_BIT_WIDTH-1:0] single_fp,
    input  logic [9*P_BIT_WIDTH-1:0] parallel_fp,
    output logic blast_output,
    output logic finish_process,
    output logic clr,
    output logic sample_type,//edited
    output logic shift_single_fz,
    output logic shift_single_fp,
    output logic shift_parallel_fz,
    output logic shift_parallel_fp,
    output logic valid_single_fz,
    output logic valid_single_fp,
    output logic valid_parallel_fz,
    output logic valid_parallel_fp
    );
logic [$clog2(N_VEC)-1:0] q_count,d_count;
logic q_st,d_st,q_fin,d_fin,correct_fz_parallel,correct_fp_parallel,correct_fz_serial,correct_fp_serial;
logic [2:0] correct_fz_p;
logic [8:0] correct_fp_p;

always_ff @(posedge clk) begin
   if(rst)begin
      q_count <= '0;
      q_st <= '0;
      q_fin <= '0;
   end else begin
      q_count <= d_count;
      q_st <= d_st;
      q_fin <= d_fin;
   end
end

assign clr = q_fin;
//assign clr = q_fin&(~q_st);
assign d_fin = blast_output;
assign finish_process = q_fin;
assign sample_type = q_st;

always_comb begin
   d_st = q_st;
   if((q_count == N_VEC)&&(d_count == 0))
      d_st = ~q_st;
end

always_comb begin
   correct_fz_p[2] = (parallel_fz[3*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH] == 3'b111) ? 0 : 1;
   correct_fz_p[1] = (parallel_fz[2*Z_BIT_WIDTH-1 -: Z_BIT_WIDTH] == 3'b111) ? 0 : 1;
   correct_fz_p[0] = (parallel_fz[Z_BIT_WIDTH-1 : 0] == 3'b111) ? 0 : 1;
correct_fz_serial = correct_fz_p[2];
   correct_fp_p[8] = (parallel_fp[9*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[7] = (parallel_fp[8*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[6] = (parallel_fp[7*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[5] = (parallel_fp[6*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[4] = (parallel_fp[5*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[3] = (parallel_fp[4*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[2] = (parallel_fp[3*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[1] = (parallel_fp[2*P_BIT_WIDTH-1 -: P_BIT_WIDTH] == 7'b1111111) ? 0 : 1;
   correct_fp_p[0] = (parallel_fp[P_BIT_WIDTH-1 : 0] == 7'b1111111) ? 0 : 1;
correct_fp_serial = correct_fp_p[8];
correct_fz_parallel = (correct_fz_p != 3'b111) ? 0 : 1;
correct_fp_parallel = (correct_fp_p != 9'b111111111) ? 0 : 1;
end

always_comb begin
d_count = q_count;
blast_output = 0;
shift_single_fz = 0;
shift_single_fp = 0;
shift_parallel_fz = 0;
shift_parallel_fp = 0;
valid_single_fz = 0;
valid_single_fp = 0;
valid_parallel_fz = 0;
valid_parallel_fp = 0;
   if((interrupt)&&(q_count < N_VEC)&&(!finish_process))begin//correction required
      if((!sample_type)&&(bit_counter > 0))begin
         if((bit_counter < 9) || (q_count > N_VEC-3))begin
             shift_single_fz = 1;
             if(correct_fz_serial)begin
                valid_single_fz = 1;
                d_count = q_count + 1;
             end
          end else begin
             if(correct_fz_parallel)begin
                shift_parallel_fz = 1;
                valid_parallel_fz = 1;
                d_count = q_count + 3;
             end else begin
                shift_single_fz = 1;
                if(correct_fz_serial)begin
                   valid_single_fz = 1;
                   d_count = q_count + 1;
                end
             end
          end
      end 
      else if((sample_type)&&(bit_counter > 6)&&(!finish_process)) begin
         if((bit_counter < 63) || (q_count > N_VEC-9))begin
             shift_single_fp = 1;
             if(correct_fp_serial)begin
                valid_single_fp = 1;
                d_count = q_count + 1;
             end
         end else begin
             if(correct_fp_parallel)begin
                shift_parallel_fp = 1;
                valid_parallel_fp = 1;
                d_count = q_count + 9;
             end else begin
                shift_single_fp = 1;
                if(correct_fp_serial)begin
                   valid_single_fp = 1;
                   d_count = q_count + 1;
                end
             end
          end
      end
   end
   if(q_count == N_VEC)begin
      d_count = 0;
      blast_output = 1;
   end
end

endmodule