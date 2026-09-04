`timescale 1ns / 1ps 

import keccak_pkg::*;
import rsdp_pkg::*;

module dig_cmt0_to_chall_1(
    input  logic clk,
    input  logic rst,
    input  logic init,
    input  logic fin_gen_inst,
    
    input  logic valid_o,
    input  logic [w-1:0]data_o,
    
    input  logic message_in,
    input  logic [w-1:0]message,
    
    input  logic rsp_sense,
    input  logic rsp,
    input  logic [w-1:0]data_memory,
    
    output logic [w-1:0] data_out_c,//--
    output logic clear_c,//--
    output logic ready_o_c,//--
    output logic valid_i_c,//--
    
    output logic occupied, //--
    output logic lower_occ, //--
    output logic raise_occ,//--
    
    output logic [1:0]select_branch_cmt0,//--
    output logic req_cmt_0,//--
    output logic req_cmt_1,//--
    
    output logic shift_spare_ra,//--
    output logic shift_spare_rb,//--
    input  logic [w-1:0] output_a,
    input  logic [w-1:0] output_b,
    
    output logic rotate_tmp1,//--
    output logic rotate_tmp2,//--
    output logic shift_tmp1,//--
    output logic shift_tmp2,//--
    input  logic [w-1:0] output_tmp1,
    input  logic [w-1:0] output_tmp2,
    
    output logic write_dig_cmt,
    output logic rotate_salt_c,
    input  logic [w-1:0]salt,
    
    output logic valid_o_en,
    output logic ready_o_en,
    input  logic fin_chall,
    
    output logic next_op_c,
    
    input  logic [w-1:0] data_out_d,//--
    input  logic clear_d,//--
    input  logic ready_o_d,//--
    input  logic valid_i_d//--
    );
     
typedef enum logic [4:0] {
        _IDLE,
        //x4
        _INITIAL,
        _HEADER,
        _PREPARE,
        _GET,
        _CLEAR,
        
        _HEADER_DIG_0,
        _PREPARE_DIG_0,
        _GET_DIG_0,
        _CLEAR_DIG_0,
        
        _INITIAL_DIG_1,
        _HEADER_DIG_1,
        _PREPARE_DIG_1,
        _GET_DIG_1,
        _CLEAR_DIG_1,
        
        _PREPARE_DIG_CMT,
        _GET_DIG_CMT,
        _CLEAR_DIG_CMT,
        
        _HEADER_MSG,
        _PREPARE_MSG,
        _GET_MSG,
        _CLEAR_MSG,
        
        _PREPARE_DIG_CH1,
        _GET_DIG_CH1,
        _CLEAR_DIG_CH1,
        
        _PREPARE_CH1,
        _GET_CH1,
        _CLEAR_CH1,
        
        _PAUSE
    } state_t;
state_t q_state, d_state;
logic [12:0] q_count, d_count,q_message,d_message;
logic [2:0] q_sel, d_sel;
logic [4:0] q_block, d_block;
logic shift_spare;
logic pause;
logic shift_spare_ra_fsm;
logic shift_spare_rb_fsm;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _IDLE;
      q_count <= 0;
      q_sel   <= 0;    
      q_block <= 0;
      q_message <= 0;
   end else begin
      q_state <= d_state;
      q_count <= d_count;
      q_sel   <= d_sel;
      q_block <= d_block;
      q_message <= d_message;
   end
end 

assign select_branch_cmt0 = q_sel[1:0];
assign shift_spare_ra = (shift_spare & (~select_branch_cmt0[1]))|shift_spare_ra_fsm;
assign shift_spare_rb = (shift_spare & ( select_branch_cmt0[1]))|shift_spare_rb_fsm;

always_comb begin
d_state = q_state;
d_count = q_count;
d_sel   = q_sel;
d_block = q_block;
d_message = q_message;
   data_out_c = 0;
   clear_c = 0;
   ready_o_c = 0;
   valid_i_c = 0;
    
   occupied = 0;
   lower_occ = 0;
   raise_occ = 0;
    
//   select_branch_cmt0 = 0;
   req_cmt_0 = 0;
   req_cmt_1 = 0;
    
   shift_spare_ra_fsm = 0;
   shift_spare_rb_fsm = 0;
   shift_spare = 0;
    
   rotate_tmp1 = 0;
   rotate_tmp2 = 0;
   shift_tmp1 = 0;
   shift_tmp2 = 0;
   
   pause = 0;
   write_dig_cmt = 0;
   rotate_salt_c = 0;
   
   valid_o_en = 0;
   ready_o_en = 0;
   
   next_op_c = 0;
   
   case(q_state)
      _IDLE:begin
         if(fin_gen_inst)begin
            d_state = _INITIAL;
            d_count = 0;
            d_sel   = 0;
         end
      end
        //x4
      _INITIAL:begin
         req_cmt_0 = 1;
         d_count = 0;
         d_state = _HEADER;
      end
      _HEADER:begin
         if(rsp_sense)begin
            valid_i_c = 1;
            ready_o_c = 1;
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = ((LEAVES[q_sel])*2*LAMBDA) + 16;
            d_count = 0;
            d_state = _PREPARE;
         end
      end
      _PREPARE:begin
         ready_o_c = 1;
         if(rsp)begin
            valid_i_c = 1;
            d_count   = q_count + 1;
            data_out_c = data_memory;
         end
         if(q_count == ((LEAVES[q_sel])*2*(LAMBDA/w)))begin
            d_count   = 0;
            valid_i_c = 1;
            data_out_c = EndianSwitcher#(w)::switch(HASH_CONST);
            d_state   = _GET;
         end
      end
      _GET:begin
         ready_o_c = 1;
         if(valid_o)begin
            shift_spare = 1;
            d_count     = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR;
               d_sel = q_sel + 1;
            end
         end
      end
      _CLEAR:begin
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            if(q_sel == 4)begin
               d_sel = 0;
               d_state = _HEADER_DIG_0;
            end else begin
               d_state = _INITIAL;
            end
         end
      end
      
      _HEADER_DIG_0:begin
         valid_i_c = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = (8*LAMBDA) + 16;
         end
         if(q_count == 1)begin
            d_count = 0;
            d_block = 0;
            d_state = _PREPARE_DIG_0;
         end
      end
      _PREPARE_DIG_0:begin
         valid_i_c = 1;
         ready_o_c = 1;
         shift_spare_ra_fsm = 0;
         shift_spare_rb_fsm = 0;
         d_count = q_count + 1;
         if(q_block == B_SIZE)begin
            d_count = q_count;
            pause = 1;
         end
         d_block = q_block + 1;
         if((q_count >= 0)&&(q_count < (4*(LAMBDA/w)))&&(!pause))begin
            shift_spare_ra_fsm = 1;
            data_out_c     = output_a;
         end
         if((q_count >= (4*(LAMBDA/w)))&&(q_count < (8*(LAMBDA/w)))&&(!pause))begin
            shift_spare_rb_fsm = 1;
            data_out_c     = output_b;
         end
         if(q_count == (8*(LAMBDA/w)))begin
            shift_spare_ra_fsm = 0;
            shift_spare_rb_fsm = 0;
            data_out_c = EndianSwitcher#(w)::switch(HASH_CONST);
            d_block = 0;
            d_count = 0;
            d_state = _GET_DIG_0;
         end
      end
      _GET_DIG_0:begin
         ready_o_c = 1;
         if(valid_o)begin
            shift_tmp1 = 1;
            d_count = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR_DIG_0;
            end
         end
      end
      _CLEAR_DIG_0:begin
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _INITIAL_DIG_1;
         end
      end
      
      _INITIAL_DIG_1:begin
         req_cmt_1 = 1;
         d_state = _HEADER_DIG_1;
      end
      _HEADER_DIG_1:begin
         if(rsp_sense)begin
            valid_i_c = 1;
            ready_o_c = 1;
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = (T_VEC*2*LAMBDA) + 16;
            d_state = _PREPARE_DIG_1;
         end
      end
      _PREPARE_DIG_1:begin
         ready_o_c = 1;
         if(rsp)begin
            valid_i_c = 1;
            d_count   = q_count + 1;
            data_out_c = data_memory;
         end
         if(q_count == (T_VEC*2*(LAMBDA/w)))begin
            d_count   = 0;
            valid_i_c = 1;
            data_out_c = EndianSwitcher#(w)::switch(HASH_CONST);
            d_state   = _GET_DIG_1;
         end
      end
      _GET_DIG_1:begin
         ready_o_c = 1;
         if(valid_o)begin
            shift_tmp2 = 1;
            d_count    = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR_DIG_1;
            end
         end
      end
      _CLEAR_DIG_1:begin
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _PREPARE_DIG_CMT;
         end
      end
      
      _PREPARE_DIG_CMT:begin
         d_count = q_count + 1;
         valid_i_c = 1;
         if(q_count == 0)begin
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = (4*LAMBDA) + 16;
         end
         if(q_count == 1)begin
            data_out_c = 0;
         end
         if((q_count >= 2)&&(q_count <(2*(LAMBDA/w))+2))begin
            ready_o_c = 1;
            data_out_c = output_tmp1;
            rotate_tmp1 = 1;
         end
         if((q_count >= (2*(LAMBDA/w))+2)&&(q_count <(4*(LAMBDA/w))+2))begin
            ready_o_c = 1;
            data_out_c = output_tmp2;
            rotate_tmp2 = 1;
         end
         if(q_count == (4*(LAMBDA/w))+2)begin
            ready_o_c = 1;
            data_out_c = EndianSwitcher#(w)::switch(HASH_CONST);
            d_state   = _GET_DIG_CMT;
            d_count   = 0;
         end
      end
      _GET_DIG_CMT:begin
      ready_o_c = 1;
         if(valid_o)begin
            shift_tmp1 = 1;
            write_dig_cmt = 1;
            d_count    = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR_DIG_CMT;
            end
         end
      end
      _CLEAR_DIG_CMT:begin
      d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _HEADER_MSG;
            lower_occ = 1;
         end
      end
        
      _HEADER_MSG:begin
         if(message_in)begin
            d_count = q_count + 1;
            valid_i_c = 1;
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = (message*8);
            d_message = message;////assume the HASH DOMAIN SEPARATION CONSTANT has already been appended to the message
         end
         if(q_count == 1)begin
            occupied = 1;
            data_out_c = 0;
            valid_i_c = 0;
            d_count = q_message;
            d_block = 0;
            d_state = _PREPARE_MSG;
         end
      end
      _PREPARE_MSG:begin
         d_block = q_block;
         d_count = q_count;
         occupied = 0;
         ready_o_c = 1;
         if((message_in)||((q_block >= B_SIZE)&&(q_block <= 23)))begin
            d_block = q_block + 1;
            if(q_block == 23)begin
               d_block = 0;
            end
         end
         if((message_in)||(q_block >= B_SIZE))begin
            d_count = q_count - 8;
            valid_i_c = 1;
            data_out_c = message;
            if(q_count < 8)begin
               d_count = 0;
               d_block = 0;
               d_state = _GET_MSG;
               raise_occ = 1;
            end
         end
         if(q_block >= B_SIZE)begin
            occupied = 1;
         end
      end
      _GET_MSG:begin
      ready_o_c = 1;
         if(valid_o)begin
            shift_tmp2 = 1;
            d_count    = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR_MSG;
            end
         end
      end
      _CLEAR_MSG:begin
      d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _PREPARE_DIG_CH1;
         end
      end
        
      _PREPARE_DIG_CH1:begin
         valid_i_c = 1;
         ready_o_c = 1;
         rotate_tmp1 = 0;
         rotate_tmp2 = 0;
         rotate_salt_c = 0;
         d_count = q_count + 1;
         d_block = q_block + 1;
         data_out_c = 0;
         if(q_block == B_SIZE + 2)begin
            d_count = q_count;
            pause = 1;
         end
         if(q_count == 0)begin
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = (6*LAMBDA) + 16;
         end
         if((q_count >= 2)&&(q_count <(2*(LAMBDA/w))+2))begin
            data_out_c = output_tmp2;
            rotate_tmp2 = 1;
         end
         if((q_count >= (2*(LAMBDA/w))+2)&&(q_count <(4*(LAMBDA/w))+2))begin
            data_out_c = output_tmp1;
            rotate_tmp1 = 1;
         end
         if((q_count >= (4*(LAMBDA/w))+2)&&(q_count <(6*(LAMBDA/w))+2)&&(!pause))begin
            data_out_c = salt;
            rotate_salt_c = 1;
         end
         if(q_count == (6*(LAMBDA/w))+2)begin
            data_out_c = EndianSwitcher#(w)::switch(HASH_CONST);
            d_state   = _GET_DIG_CH1;
            d_count   = 0;
            d_block   = 0;
         end
      end
      _GET_DIG_CH1:begin
      ready_o_c = 1;
         if(valid_o)begin
            shift_tmp2 = 1;
            d_count    = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_c = 1;
               d_count = 0;
               d_state = _CLEAR_DIG_CH1;
            end
         end
      end
      _CLEAR_DIG_CH1:begin
      d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _PREPARE_CH1;
         end
      end
        
      _PREPARE_CH1:begin
         ready_o_en = 1;
         valid_i_c = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out_c[63:60] = SHAKE_TYPE;
            data_out_c[59:32] = 'h800000;
            data_out_c[31:0]  = 2*LAMBDA + 16;
         end
         if(q_count == 1)begin
            data_out_c = 0;
         end
         if((q_count >= 2)&&(q_count < 2*(LAMBDA/w)+2))begin
            data_out_c = output_tmp2;
            rotate_tmp2 = 1;
         end
         if(q_count == 2*(LAMBDA/w)+2)begin
            data_out_c = EndianSwitcher#(w)::switch(T_VEC + C_VEC);
            d_count = 0;
            d_state = _GET_CH1;
         end
      end
      _GET_CH1:begin
         ready_o_en = 1;
         valid_o_en = 1;
         if(fin_chall)begin
            ready_o_en = 0;
            valid_o_en = 0;
            clear_c = 1;
            d_state = _CLEAR_CH1;
         end
      end
      _CLEAR_CH1:begin
      d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _PAUSE;
            next_op_c = 1;
         end
      end
      
      _PAUSE:begin
      //come back after signature is finished
           data_out_c = data_out_d;
           clear_c    = clear_d;
           ready_o_c  = ready_o_d;
           valid_i_c  = valid_i_d;
           if(init)begin
              d_state = _HEADER_MSG;
              d_count = 0;
           end
      end
      
      default:begin
         d_state = _IDLE;
      end
   endcase
end
    
endmodule