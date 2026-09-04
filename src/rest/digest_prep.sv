`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module digest_prep#(
    parameter int OFFSET = 0
)(
    input  logic clk,
    input  logic rst,
    input  logic end_matrix,
    input  logic clear,
    input  logic access,
    input  logic [w-1:0]comp_s,
    input  logic [w-1:0]comp_v,
    input  logic [w-1:0]data_temp1,
    input  logic write_cmt1,
    output logic ready,
    output logic shift_s,
    output logic shift_v,
    output logic sft_tmp1,
    output logic [w-1:0]comp_data
    );

localparam int BUFF_SIZE = (SECURITY_LVL == 1) ? 16:
                           (SECURITY_LVL == 3) ? 24:
                           (SECURITY_LVL == 5) ? 32:
                                                 16; 
                            
                                                 
logic [w-1:0]data_out,data_in;
logic [2:0] bytes;

logic q_ready, d_ready, shift_in, flush;
logic [7:0]  q_count, d_count;
logic [15:0] q_round_count, d_round_count;
typedef enum logic [5:0] {
        IDLE,
        GET_S,
        GET_V,
        GET_SALT,
        ADD_CONST,
        FLUSH
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk)begin
   if(rst)begin
      q_ready       <= 0;
      q_count       <= 0;
      q_state       <= IDLE;
      q_round_count <= 0;
   end else begin
      q_ready       <= d_ready;
      q_count       <= d_count;
      q_state       <= d_state;
      q_round_count <= d_round_count;
   end
end

comp_unit cu(
    .clk      (clk),
    .reset    (rst),
    .shift_in (shift_in|shift_s|shift_v|sft_tmp1),
    .bytes    (bytes),
    .data_in  (data_in),
    .flush    (flush),
    .data_out (data_out),
    .valid_out(valid_out)
    );
    
pad_generator #(
     .DEPTH(BUFF_SIZE)
)buffer(
   .clk      (clk),
   .reset    (rst),
   .shift    (valid_out),
   .rotate   (access),
   .data_in  (data_out),
   .data_out (comp_data)
);

always_comb begin
   d_count = q_count;
   d_state = q_state;
   d_round_count = q_round_count;
   bytes = 0;
   shift_in = 0;
   flush = 0;
   data_in = 0;
   shift_s = 0;
   shift_v = 0;
   sft_tmp1 = 0;
   case(q_state)
      IDLE:begin
         if(end_matrix)begin
            d_state = GET_S;
         end
      end
      GET_S:begin
         d_count = q_count + 1;
         shift_s = 1;
         data_in = comp_s;
         if(q_count == S_SIZE - 1)begin
            d_count = 0;
            bytes = S_REM;
            d_state = GET_V;
         end
      end
      GET_V:begin
         if(!write_cmt1)begin
            d_count = q_count + 1;
            shift_v = 1;
            data_in = comp_v;
            if(q_count == V_SIZE - 1)begin
               d_count = 0;
               bytes = V_REM;
               d_state = GET_SALT;
            end
         end
      end
      GET_SALT:begin
         d_count = q_count + 1;
         sft_tmp1 = 1;
         data_in = data_temp1;
         if(q_count == (2*(LAMBDA/w)) - 1)begin
            d_count = 0;
            bytes = 0;
            d_state = ADD_CONST;
         end
      end
      ADD_CONST:begin
         shift_in = 1;
         data_in = EndianSwitcher#(w)::switch(q_round_count + OFFSET + HASH_CONST + C_VEC);
         d_round_count = q_round_count + 4;
         bytes = 2;
         d_state = FLUSH;
      end
      FLUSH:begin
         flush = 1;
         d_state = IDLE;
         if(q_round_count + OFFSET >= T_VEC)begin
            d_round_count = 0;
         end
      end
      default:begin
         d_state = IDLE;
      end
   endcase
end
    
always_comb begin
d_ready = q_ready;
   if(flush)begin
      d_ready = 1;
   end else if(clear)begin
      d_ready = 0;
   end
end
    
assign ready = q_ready;
    
endmodule