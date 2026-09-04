`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

localparam int INP_CNT = (2*LAMBDA)/w;

module keygen_controller(
    input  logic clk,
    input  logic reset,
    input  logic shift_seed_sk,
    input  logic valid_o,
    input  logic finished_ebar,
    input  logic finished_vt,
    output logic valid_input,
    output logic rotate_seed_sk,
    output logic [w-1:0] data_out,
    output logic [2:0] select_input,
    output logic system_ready_o,
    output logic shift_seed_vt,
    output logic rotate_seed_vt,
    output logic shift_seed_e,
    output logic rotate_seed_e,
    output logic valid_o_e,
    output logic valid_o_vt,
    output logic clear_by_system
    );
    
logic [4:0] q_counter, d_counter, q_max_counter, d_max_counter;
typedef enum logic [5:0] {
        IDLE,
        SEED_STORE,
        START_GENERATION,
        PROCESSING_OUT,
        WAIT_EBAR,
        WAIT_VT,
        START_VT,
        PROCESS_VT,
        START_EBAR,
        PROCESS_EBAR
    } state_t;
    state_t q_state, d_state;

 always_ff @(posedge clk) begin
    if(reset)begin
       q_state <= IDLE;
       q_counter <= 0;
       q_max_counter <= 0;
    end else begin
       q_state <= d_state;
       q_counter <= d_counter;
       q_max_counter <= d_max_counter;
    end
 end
 
always_comb begin
    valid_input = 0;
    rotate_seed_sk = 0;
    data_out = 0;
    select_input = 0;
    system_ready_o = 0;
    shift_seed_vt = 0;
    rotate_seed_vt = 0;
    shift_seed_e = 0;
    rotate_seed_e = 0;
    valid_o_e = 0;
    valid_o_vt = 0;
    clear_by_system = 0;
    d_state = q_state;
    d_counter = q_counter;
    d_max_counter = q_max_counter;
    
    
    case(q_state)
       IDLE:begin
          d_max_counter = (2*LAMBDA)/w;
          d_state = SEED_STORE;
       end
       SEED_STORE:begin
          if(shift_seed_sk)begin
             d_counter = q_counter + 1;
             if(q_counter == q_max_counter - 1)begin
                d_counter = 0;
                d_max_counter = ((2*LAMBDA)/w) + 3;
                d_state = START_GENERATION;
             end
          end
       end
       START_GENERATION:begin
          valid_input = 1;
          d_counter = q_counter + 1;
          if(q_counter == 0)begin
             data_out[63:60] = SHAKE_TYPE;
             data_out[59:32] = 4*LAMBDA;
             data_out[31:0] = 2*LAMBDA + 16;
             select_input = 3'b001;
          end
          if(q_counter == 1)begin
             data_out = 0;
             select_input = 0;
          end
          if(q_counter >= 2 && q_counter < q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b010;
             rotate_seed_sk = 1;
          end
          if(q_counter == q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b001;
             data_out = EndianSwitcher#(w)::switch(KGCONST + 1);
             rotate_seed_sk = 0;
             d_state = PROCESSING_OUT;
          end
       end
       PROCESSING_OUT:begin
          d_max_counter = (4*LAMBDA)/w;
          d_counter = 0;
          system_ready_o = 1;
          valid_input = 0;
          data_out = 0;
          select_input = 0;
          if(valid_o)begin
             d_counter = q_counter + 1;
             shift_seed_e = 1;
             if(q_counter >= (d_max_counter/2) && q_counter < (q_max_counter - 1))begin
                shift_seed_e = 0;
                shift_seed_vt = 1;
             end
             if(q_counter == (q_max_counter - 1))begin
                shift_seed_e = 0;
                shift_seed_vt = 1;
                d_state = WAIT_EBAR;
                clear_by_system = 1;
                d_max_counter = (2*LAMBDA)/w + 3;
                d_counter = 0;
             end
          end
       end
       WAIT_EBAR:begin
          d_state = START_EBAR;
       end
       WAIT_VT:begin
          d_state = START_VT;
       end
       START_VT:begin
          valid_input = 1;
          d_counter = q_counter + 1;
          if(q_counter == 0)begin
             data_out[63:60] = SHAKE_TYPE;
             data_out[59:32] = 'h800000;//'h15540;
             data_out[31:0] = 2*LAMBDA + 16;
             select_input = 3'b001;
          end
          if(q_counter == 1)begin
             data_out = 0;
             select_input = 0;
          end
          if(q_counter >= 2 && q_counter < q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b011;
             rotate_seed_vt = 1;
          end
          if(q_counter == q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b001;
             data_out = EndianSwitcher#(w)::switch(KGCONST + 2);
             rotate_seed_vt = 0;
             d_state = PROCESS_VT;
          end
       end
       PROCESS_VT:begin
          system_ready_o = 1;
          valid_o_vt = 1;
          if(finished_vt)begin
             system_ready_o = 0;
             valid_o_vt = 0;
             d_state = IDLE;
             d_max_counter = (2*LAMBDA)/w + 3;
             d_counter = 0;
          end
       end
       START_EBAR:begin
          valid_input = 1;
          d_counter = q_counter + 1;
          if(q_counter == 0)begin
             data_out[63:60] = SHAKE_TYPE;
             data_out[59:32] = 'h800000;
             data_out[31:0] = 2*LAMBDA + 16;
             select_input = 3'b001;
          end
          if(q_counter == 1)begin
             data_out = 0;
             select_input = 0;
          end
          if(q_counter >= 2 && q_counter < q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b100;
             rotate_seed_e = 1;
          end
          if(q_counter == q_max_counter - 1)begin
             system_ready_o = 1;
             select_input = 3'b001;
             data_out = EndianSwitcher#(w)::switch(KGCONST + 3);
             rotate_seed_e = 0;
             d_state = PROCESS_EBAR;
          end
       end
       PROCESS_EBAR:begin
          system_ready_o = 1;
          valid_o_e = 1;
          if(finished_ebar)begin
             system_ready_o = 0;
             valid_o_e = 0;
             d_state = WAIT_VT;
             d_max_counter = (2*LAMBDA)/w + 3;
             d_counter = 0;
          end
       end
       default: d_state = IDLE;
    endcase
end

endmodule
