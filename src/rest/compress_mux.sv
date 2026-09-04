`timescale 1ns / 1ps
/////start from here
import keccak_pkg::*;
import rsdp_pkg::*;

module compress_mux(
    input  logic clk,
    input  logic rst,
    input  logic response_vector,
    input  logic [w-1:0]y1,
    input  logic [w-1:0]y2,
    input  logic [w-1:0]y3,
    input  logic [w-1:0]y4,
    input  logic [w-1:0]dig_chall_1,
    input  logic start_op,
    output logic finish_op,
    output logic write_y_resp,
    output logic [w-1:0]y2mem,//
    output logic request_vectors,
    output logic push_y1,
    output logic push_y2,
    output logic push_y3,
    output logic push_y4,
    output logic push_dig_chall_1,
    output logic shift_in,
    output logic [2:0]bytes,
    output logic [w-1:0]data_in,
    output logic flush
    );
    
localparam int VEC_DURATION = (N_VEC/16);
    
logic q_0,d_0,q_1,d_1,start_compression,push_y;
logic [8:0] q_iteration_count,d_iteration_count;
logic [2:0] q_inner_count,d_inner_count;
logic [5:0] q_count,d_count;
typedef enum logic [2:0] {
        _IDLE,
        _READ_VEC,
        _COMP_Y,
        _CHECK,
        _FINAL
    } state_t;
    
state_t q_state,d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_0               <= 0;
      q_1               <= 0; 
      q_iteration_count <= 0;
      q_inner_count     <= 0;
      q_count           <= 0;
      q_state           <= _IDLE;
   end else begin
      q_0               <= d_0;
      q_1               <= d_1;
      q_iteration_count <= d_iteration_count;
      q_inner_count     <= d_inner_count;
      q_count           <= d_count;
      q_state           <= d_state;
   end
end 
    
assign d_0 = response_vector;
assign d_1 = (~d_0)&q_0;
assign start_compression = q_1;
assign push_y1 = (push_y&&(q_inner_count == 0));
assign push_y2 = (push_y&&(q_inner_count == 1));
assign push_y3 = (push_y&&(q_inner_count == 2));
assign push_y4 = (push_y&&(q_inner_count == 3));

always_comb begin
   case(q_inner_count)
      0       : y2mem = y1;
      1       : y2mem = y2;
      2       : y2mem = y3;
      3       : y2mem = y4;
      default : y2mem = 0;
   endcase
end
    
always_comb begin
   d_iteration_count = q_iteration_count;
   d_inner_count     = q_inner_count;
   d_count           = q_count;
   d_state           = q_state;
   write_y_resp = 0;
   request_vectors = 0;
   push_y = 0;
   push_dig_chall_1 = 0;
   shift_in = 0;
   bytes = 0;
   data_in = 0;
   flush = 0;
   finish_op = 0;
   case(q_state)
      _IDLE:begin
         if(start_op)begin
            d_count           = 0;
            d_state           = _READ_VEC;
         end
      end
      _READ_VEC:begin
      d_count = q_count + 1;
      request_vectors = 0;
         if(q_count <= VEC_DURATION)begin
            request_vectors = 1;
         end
         if(start_compression)begin
            d_count = 0;
            d_state = _COMP_Y;
         end
      end
      _COMP_Y:begin
      d_count = q_count + 1;
      write_y_resp = 1;
      data_in = y2mem;
      push_y = 1;
      shift_in = 1;
      bytes = 0;
         if(q_count == Y_SIZE - 1)begin
            bytes = Y_REM;
            d_count = 0;
            d_inner_count = q_inner_count + 1;
            d_state = _CHECK;
         end
      end
      _CHECK:begin
      d_state = _COMP_Y;
      finish_op = 0;
         if(q_inner_count == 4)begin
            d_state = _IDLE;
            d_iteration_count = q_iteration_count + 4;
            finish_op = 1;
            d_inner_count = 0;
         end 
         if(q_inner_count + q_iteration_count == T_VEC)begin
             finish_op = 1;
             d_state = _FINAL;
             d_inner_count = 0;
             d_iteration_count = 0;
             d_count = 0;
         end
      end
      _FINAL:begin
         d_count = q_count + 1;
         if(q_count < (2*(LAMBDA/w)))begin
            push_dig_chall_1 = 1;
            shift_in = 1;
            data_in = dig_chall_1;
            bytes = 0;
         end
         if(q_count == (2*(LAMBDA/w)))begin
            shift_in = 1;
            data_in = EndianSwitcher#(w)::switch(HASH_CONST);
            bytes = 2;
         end
         if(q_count == (2*(LAMBDA/w))+1)begin
            flush = 1;
            d_count = 0;
            d_state = _IDLE;
         end
      end
      default:begin
         d_state = _IDLE;
      end
   endcase
end
    
endmodule