`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module gen_sec_chall_fsm(
    input  logic clk,
    input  logic rst,
    input  logic flush,
    
    input  logic valid_o,
    output logic valid_o_active,
    input  logic [w-1:0]data_o,
    
    output logic rotate_tmp_2,
    output logic shift_tmp_2,
    input  logic [w-1:0]tmp_2_out,
    
    input  logic rsp_sense,
    input  logic rsp,
    input  logic [w-1:0]data_memory,
    
    output logic [w-1:0] data_out_d,//--
    output logic clear_d,//--
    output logic ready_o_d,//--
    output logic valid_i_d,//--
    
    output logic req_pulse_yt,
    output logic ready_o_system,
    output logic next_stage,
    
    input logic fin_chall2
    );
    
localparam int MAX_ADDRESS = (SECURITY_LVL == 1) ? 2203:
                             (SECURITY_LVL == 3) ? 5145:
                             (SECURITY_LVL == 5) ? 8836:
                                                   2203;
    
logic [13:0] q_count,d_count;
typedef enum logic [3:0] {
        _IDLE,
     
        _HEADER,
        _PREPARE,
        _GET,
        _CLEAR,
        
        _PREPARE_CH2,
        _GET_CH2,
        _CLEAR_CH2
    } state_t;
state_t q_state, d_state;
    
always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _IDLE;
      q_count <= 0;
   end else begin
      q_state <= d_state;
      q_count <= d_count;
   end
end

always_comb begin
   d_state = q_state;
   d_count = q_count;
   data_out_d = 0;
   clear_d = 0;
   ready_o_d = 0;
   valid_i_d = 0;
   ready_o_system = 0;
   next_stage = 0;
   valid_o_active = 0;
   rotate_tmp_2 = 0;
   shift_tmp_2 = 0;
   req_pulse_yt = 0;
   case(q_state)
      _IDLE:begin
         d_count   = 0;
         if(flush||(q_count > 0))begin
            d_count   = q_count + 1;
            if(q_count == 3)begin
               d_count = 0;
               req_pulse_yt = 1;
               d_state = _HEADER;
            end
         end
      end
      _HEADER:begin
         if(rsp_sense)begin
            valid_i_d = 1;
            ready_o_d = 1;
            data_out_d[63:60] = SHAKE_TYPE;
            data_out_d[59:32] = 'h800000;
            data_out_d[31:0]  = ((((8*Y_SIZE)-(8-Y_REM))*T_VEC) + (16*(LAMBDA/w)) + 2)*8;
            d_count = 0;
            d_state = _PREPARE;
         end
      end
      _PREPARE:begin
         ready_o_d = 1;
         if(rsp)begin
            valid_i_d = 1;
            d_count   = q_count + 1;
            data_out_d = data_memory;
            if(q_count == MAX_ADDRESS - 1)begin
               d_count   = 0;
               d_state   = _GET;
            end
         end
      end
      _GET:begin
         ready_o_d = 1;
         if(valid_o)begin
            shift_tmp_2 = 1;
            d_count     = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_d = 1;
               d_count = 0;
               d_state = _CLEAR;
            end
         end
      end
      _CLEAR:begin
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _PREPARE_CH2;
         end
      end
      
      _PREPARE_CH2:begin
         ready_o_system = 1;
         valid_i_d = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out_d[63:60] = SHAKE_TYPE;
            data_out_d[59:32] = 'h800000;
            data_out_d[31:0]  = 2*LAMBDA + 16;
         end
         if(q_count == 1)begin
            data_out_d = 0;
         end
         if((q_count >= 2)&&(q_count < 2*(LAMBDA/w)+2))begin
            data_out_d = tmp_2_out;
            rotate_tmp_2 = 1;
         end
         if(q_count == 2*(LAMBDA/w)+2)begin
            data_out_d = EndianSwitcher#(w)::switch(T_VEC + C_VEC + 1);
            d_count = 0;
            d_state = _GET_CH2;
         end
      end
      _GET_CH2:begin
         ready_o_system = 1;
         valid_o_active = 1;
         if(fin_chall2)begin
            ready_o_system = 0;
            valid_o_active = 0;
            clear_d = 1;
            d_state = _CLEAR_CH2;
         end
      end
      _CLEAR_CH2:begin
      d_count = q_count + 1;
         if(q_count == 4)begin
            d_count    = 0;
            d_state    = _IDLE;
            next_stage = 1;
         end
      end
      
      default:begin
         d_state = _IDLE;
      end
   endcase
end
    
endmodule
