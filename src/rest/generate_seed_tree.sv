`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module generate_seed_tree(
    input  logic clk,
    input  logic rst,
    input  logic start_tree_gen,
    input  logic [w-1:0] seed_lambda,
    input  logic [w-1:0] salt,
    input  logic [w-1:0] data_temp1,
    input  logic [w-1:0] data_temp2,
    input  logic valid_o,
    output logic [w-1:0] data_out,
    output logic clear,
    output logic ready_o,
    output logic valid_i,
    output logic rotate_seed_lambda,
    output logic rotate_salt,
    output logic shift_tmp1,
    output logic shift_tmp2,
    output logic finished_tree,
    output logic write_seed,
    output logic initial_writes
    );
    
logic [9:0] q_counter, d_counter;
typedef enum logic [5:0] {
        IDLE,
        PREPARE_0,
        GET_0,
        WAIT_0,
        PREPARE_1,
        GET_1,
        WAIT_1,
        PREPARE_2,
        GET_2,
        WAIT_2,
        PREPARE_3,
        GET_3,
        WAIT_3,
        PREPARE_4,
        GET_4,
        WAIT_4
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state    <= IDLE;
      q_counter  <= 0;
   end else begin
      q_state    <= d_state;
      q_counter  <= d_counter;
   end
end 

always_comb begin
   d_state = q_state;
   d_counter = q_counter;
   data_out = 0;
   clear = 0;
   ready_o = 0;
   valid_i = 0;
   rotate_seed_lambda = 0;
   rotate_salt = 0;
   shift_tmp1 = 0;
   shift_tmp2 = 0;
   finished_tree = 0;
   write_seed = 0;
   initial_writes = 0;
   case(q_state)
      IDLE:begin
         if(start_tree_gen)begin
            d_state = PREPARE_0;
         end
      end
      PREPARE_0:begin//////////////////////////////////////////////////////////////////////
         valid_i = 1;
         d_counter = q_counter + 1;
         if(q_counter == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;//4*LAMBDA;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_counter == 1)begin
            data_out = 0;
         end
         if((q_counter >= 2)&&(q_counter <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = seed_lambda;
            rotate_seed_lambda = 1;
         end
         if((q_counter >= (LAMBDA/w)+2)&&(q_counter <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_counter == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(64'h0);
            d_state = GET_0;
            d_counter = 0;
         end
      end
      GET_0:begin
         ready_o = 1;
         if(valid_o)begin
            d_counter = q_counter + 1;
            if((q_counter >= 0)&&(q_counter <= ((2*LAMBDA)/w)-1))begin
               shift_tmp1 = 1;
            end
            if((q_counter >= ((2*LAMBDA)/w))&&(q_counter <= ((4*LAMBDA)/w)-1))begin
               shift_tmp2 = 1;
               if(q_counter == ((4*LAMBDA)/w)-1)begin
                  clear = 1;
                  d_counter = 0;
                  d_state = WAIT_0;
               end
            end
         end
      end
      WAIT_0:begin
         d_counter = q_counter + 1;
         if(q_counter == 4)begin
            d_state = PREPARE_1;
            d_counter = 0;
         end
      end
      PREPARE_1:begin//////////////////////////////////////////////////////////////////////
         valid_i = 1;
         d_counter = q_counter + 1;
         if(q_counter == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;//(LEAVES[0])*LAMBDA;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_counter == 1)begin
            data_out = 0;
         end
         if((q_counter >= 2)&&(q_counter <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = data_temp1;
            shift_tmp1 = 1;
         end
         if((q_counter >= (LAMBDA/w)+2)&&(q_counter <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_counter == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(64'h1);
            d_state = GET_1;
            d_counter = 0;
         end
      end
      GET_1:begin
         ready_o = 1;
         if(valid_o)begin
            write_seed = 1;
            d_counter = q_counter + 1;
            if(q_counter < (4*(LAMBDA/w)))begin
               initial_writes = 1;
            end
            if(q_counter == ((LEAVES[0])*(LAMBDA/w))-1)begin
                  clear = 1;
                  d_counter = 0;
                  d_state = WAIT_1;
            end
         end
      end
      WAIT_1:begin
         d_counter = q_counter + 1;
         if(q_counter == 4)begin
            d_state = PREPARE_2;
            d_counter = 0;
         end
      end
      PREPARE_2:begin//////////////////////////////////////////////////////////////////////
         valid_i = 1;
         d_counter = q_counter + 1;
         if(q_counter == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;//(LEAVES[1])*LAMBDA;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_counter == 1)begin
            data_out = 0;
         end
         if((q_counter >= 2)&&(q_counter <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = data_temp1;
            shift_tmp1 = 1;
         end
         if((q_counter >= (LAMBDA/w)+2)&&(q_counter <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_counter == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(64'h2);
            d_state = GET_2;
            d_counter = 0;
         end
      end
      GET_2:begin
         ready_o = 1;
         if(valid_o)begin
            write_seed = 1;
            d_counter = q_counter + 1;
            if(q_counter == ((LEAVES[1])*(LAMBDA/w))-1)begin
                  clear = 1;
                  d_counter = 0;
                  d_state = WAIT_2;
            end
         end
      end
      WAIT_2:begin
         d_counter = q_counter + 1;
         if(q_counter == 4)begin
            d_state = PREPARE_3;
            d_counter = 0;
         end
      end
      PREPARE_3:begin//////////////////////////////////////////////////////////////////////
         valid_i = 1;
         d_counter = q_counter + 1;
         if(q_counter == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;//(LEAVES[2])*LAMBDA;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_counter == 1)begin
            data_out = 0;
         end
         if((q_counter >= 2)&&(q_counter <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = data_temp2;
            shift_tmp2 = 1;
         end
         if((q_counter >= (LAMBDA/w)+2)&&(q_counter <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_counter == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(64'h3);
            d_state = GET_3;
            d_counter = 0;
         end
      end
      GET_3:begin
         ready_o = 1;
         if(valid_o)begin
            write_seed = 1;
            d_counter = q_counter + 1;
            if(q_counter == ((LEAVES[2])*(LAMBDA/w))-1)begin
                  clear = 1;
                  d_counter = 0;
                  d_state = WAIT_3;
            end
         end
      end
      WAIT_3:begin
         d_counter = q_counter + 1;
         if(q_counter == 4)begin
            d_state = PREPARE_4;
            d_counter = 0;
         end
      end
      PREPARE_4:begin//////////////////////////////////////////////////////////////////////
         valid_i = 1;
         d_counter = q_counter + 1;
         if(q_counter == 0)begin
            data_out[63:60] = SHAKE_TYPE;
            data_out[59:32] = 'h800000;//(LEAVES[3])*LAMBDA;
            data_out[31:0]  = 3*LAMBDA + 16;
         end
         if(q_counter == 1)begin
            data_out = 0;
         end
         if((q_counter >= 2)&&(q_counter <= (LAMBDA/w)+1))begin
            ready_o = 1;
            data_out = data_temp2;
            shift_tmp2 = 1;
         end
         if((q_counter >= (LAMBDA/w)+2)&&(q_counter <= ((3*LAMBDA)/w)+1))begin
            ready_o = 1;
            data_out = salt;
            rotate_salt = 1;
         end
         if((q_counter == ((3*LAMBDA)/w)+2))begin
            ready_o = 1;
            data_out = EndianSwitcher#(w)::switch(64'h4);
            d_state = GET_4;
            d_counter = 0;
         end
      end
      GET_4:begin
         ready_o = 1;
         if(valid_o)begin
            write_seed = 1;
            d_counter = q_counter + 1;
            if(q_counter == ((LEAVES[3])*(LAMBDA/w))-1)begin
                  clear = 1;
                  d_counter = 0;
                  d_state = WAIT_4;
            end
         end
      end
      WAIT_4:begin
         d_counter = q_counter + 1;
         if(q_counter == 4)begin
            d_state = IDLE;
            finished_tree = 1;
            d_counter = 0;
         end
      end
      default : d_state = IDLE;
   endcase
end
    
endmodule