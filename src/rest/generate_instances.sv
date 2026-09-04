`timescale 1ns / 1ps
     
import keccak_pkg::*;
import rsdp_pkg::*;

module generate_instances(
    input  logic clk,//
    input  logic rst,//
    input  logic finished_tree,//
    input  logic [w-1:0] seed_lambda,//
    input  logic [w-1:0] salt,//
    input  logic end_pulse_cmp,
    input  logic [w-1:0] data_out_cmp,
    input  logic valid_o,
    input  logic end_instance,//
    input  logic flag,
    //new
    input  logic [w-1:0] data_out_b,
    input  logic clear_b,
    input  logic ready_o_b,
    input  logic valid_i_b,
    input  logic write_cmt0_b,
    
    output logic lower_flag,
    output logic [1:0] valid_o_select,//
    output logic [w-1:0] data_out,//
    output logic clear,//
    output logic ready_o,
    output logic ready_o_system,//
    output logic valid_i,//
    output logic rotate_seed_lambda,//
    output logic rotate_salt,//
    output logic valid_o_inst_sampler,
    //new
    output logic write_cmt0,
    output logic write_cmt1,
    output logic request_next_seed,
    output logic relocate_salt,
    output logic req_sed_pulse,
    output logic fin_gen_inst
    );
    
localparam int COMP_DURATION = (SECURITY_LVL == 1) ? 3:
                               (SECURITY_LVL == 3) ? 1:
                               (SECURITY_LVL == 5) ? 3:
                                                     3;
      
typedef enum logic [5:0] {
        IDLE,
        PREPARE_INST,
        GET_INST,
        
        COMPENSATE,
        
        PREPARE_CMT_1,
        GET_CMT_1,
        CLEAR_CMT_1,
        WAIT_,
        DECIDE
    } state_t;
state_t q_state, d_state;
    
logic [15:0] q_inner_count,d_inner_count;
logic [15:0] q_count, d_count, q_round_count, d_round_count; 

always_ff @(posedge clk) begin
   if(rst)begin
      q_state       <= IDLE;
      q_count       <= 0;
      q_round_count <= 0;
      q_inner_count <= 0;
   end else begin
      q_state       <= d_state;
      q_count       <= d_count;
      q_round_count <= d_round_count;
      q_inner_count <= d_inner_count;
   end
end 

assign valid_o_select = q_inner_count[1:0];
    
always_comb begin
   d_state       = q_state;
   d_count       = q_count;
   d_round_count = q_round_count;
   d_inner_count = q_inner_count;
   lower_flag = 0;
   data_out = 0;
   clear = 0;
   ready_o = 0;
   ready_o_system = 0;
   valid_i = 0;
   rotate_seed_lambda = 0;
   rotate_salt = 0;
   valid_o_inst_sampler = 0;
   write_cmt0 = 0;
   write_cmt1 = 0;
   request_next_seed = 0;
   relocate_salt = 0;
   req_sed_pulse = 0;
   fin_gen_inst = 0;
   case(q_state)
      IDLE:begin
         request_next_seed = 0;
         if(finished_tree)begin
            d_state       = PREPARE_INST;
            d_count       = 0;
            d_round_count = 0;
            d_inner_count = 0;
         end
      end
      PREPARE_INST:begin
         request_next_seed = 1;
         valid_i = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_count == 1)begin
            data_out = 0;
         end
         if((q_count >= 2)&&(q_count <= (LAMBDA/w)+1))begin
            ready_o_system = 1;
            data_out = seed_lambda;
            rotate_seed_lambda = 1;
         end
         if((q_count >= (LAMBDA/w)+2)&&(q_count <= ((3*LAMBDA)/w)+1))begin
            ready_o_system = 1;
            data_out = salt;
            relocate_salt = (q_round_count+q_inner_count == 0);
            rotate_salt = 1;
         end
         if((q_count == ((3*LAMBDA)/w)+2))begin
            ready_o_system = 1;
            data_out = EndianSwitcher#(w)::switch(q_round_count + q_inner_count + C_VEC);
            d_state = GET_INST;
            d_count = 0;
         end
      end
      GET_INST:begin
         request_next_seed = 1;
         valid_o_inst_sampler = 1;
         d_count = q_count;
         ready_o_system = 1;
         if((end_instance)||(q_count > 0))begin
            d_count = q_count + 1;
            ready_o_system = 0;
            if(end_instance)begin
               clear = 1;
               ready_o_system = 1;
               d_inner_count = q_inner_count + 1;
            end 
            if(q_count == 5)begin
               d_count = 0;
               d_state = PREPARE_INST;
               if(q_inner_count == 4)begin
                  d_state = PREPARE_CMT_1;
                  d_inner_count = 0;
                  d_count = 0;
               end 
               if(q_inner_count + q_round_count == T_VEC)begin
                  d_state = COMPENSATE;
                  d_inner_count = 0;
                  d_count = 0;
               end
            end
         end
      end
      
      COMPENSATE:begin
         rotate_seed_lambda = 1;
         d_count = q_count + 1;
         if(q_count == (COMP_DURATION*(LAMBDA/w))-1)begin
            d_state = PREPARE_CMT_1;
            d_count = 0;
         end
      end
      
      PREPARE_CMT_1:begin//////////////////////////////////////////////////////////////////
         request_next_seed = 1;
         valid_i = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_count == 1)begin
            data_out = 0;
         end
         if((q_count >= 2)&&(q_count <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = seed_lambda;
            rotate_seed_lambda = 1;
         end
         if((q_count >= (LAMBDA/w)+2)&&(q_count <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_count == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(q_round_count + q_inner_count + C_VEC + HASH_CONST);
            d_state = GET_CMT_1;
            d_count = 0;
         end 
      end
      GET_CMT_1:begin
         request_next_seed = 1;
         ready_o = 1;
         if(valid_o)begin
            write_cmt1 = 1;
            d_count = q_count + 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
                  clear = 1;
                  d_count = 0;
                  d_inner_count = q_inner_count + 1;
                  d_state = CLEAR_CMT_1;
            end
         end
      end
      CLEAR_CMT_1:begin
         request_next_seed = 1;
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
               if((q_inner_count == 4)||(q_inner_count + q_round_count == T_VEC))begin
                  d_state = WAIT_;
                  req_sed_pulse = 1;
                  d_inner_count = 0;
               end else begin
                  d_state = PREPARE_CMT_1;
               end
         end     
      end
      WAIT_:begin//////////////////////////////////////////////////////////////////////////
         request_next_seed = 1;
         valid_i = valid_i_b;
         clear   = clear_b;
         ready_o = ready_o_b;
         write_cmt0 = write_cmt0_b;
         data_out = data_out_b;
         if(flag)begin
            lower_flag = 1;
            d_state = DECIDE;
            d_round_count = q_round_count + 4;
         end
      end
      DECIDE:begin
         request_next_seed = 1;
         if(q_round_count > T_VEC - 1)begin
            d_state       = IDLE;
            fin_gen_inst  = 1;
         end else begin
            d_state       = PREPARE_INST;
            d_count       = 0;
            d_inner_count = 0;
         end
      end
      default:begin
         d_state       = IDLE;
         d_count       = 0;
         d_round_count = 0;
         d_inner_count = 0;
      end
   endcase
end   
  
endmodule