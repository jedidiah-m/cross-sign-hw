`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module cmt_0_control(
    input logic clk,
    input logic rst,
    input logic flag,
    input logic ready_1a,
    input logic ready_2a,
    input logic ready_1b,
    input logic ready_2b,
    input logic [w-1:0]comp_data_1a,
    input logic [w-1:0]comp_data_2a,
    input logic [w-1:0]comp_data_1b,
    input logic [w-1:0]comp_data_2b,
    input logic valid_o,
    
    input logic req_seed_pulse,
    
    output logic clear_1a,
    output logic clear_2a,
    output logic clear_1b,
    output logic clear_2b,
    
    output logic access_1a,
    output logic access_2a,
    output logic access_1b,
    output logic access_2b,
    
    output logic [w-1:0] data_out_b,
    output logic clear_b,
    output logic ready_o_b,
    output logic valid_i_b,
    output logic write_cmt0_b
    );
    
localparam int INPUT_SIZE = (((8*S_SIZE)-(8-S_REM))+((8*V_SIZE)-(8-V_REM))+(16*(LAMBDA/w))+2)*8;
localparam int MAX_COUNT = (SECURITY_LVL == 1) ? 16:
                           (SECURITY_LVL == 3) ? 25:
                           (SECURITY_LVL == 5) ? 33:
                                                 16; 

typedef enum logic [3:0] {
        _IDLE,
        _WAIT,
        _INITIALIZE,
        _PREPARE,
        _GET,
        _RESET,
        _CHECK
    } state_t;
state_t q_state, d_state;
logic [5:0] q_count, d_count;
logic [3:0] q_sel, d_sel, select;
logic [w-1:0] data_out_regs;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _IDLE;
      q_count <= 0;
      q_sel   <= 0;       
   end else begin
      q_state <= d_state;
      q_count <= d_count;
      q_sel   <= d_sel;
   end
end 

assign select = {ready_1a,ready_2a,ready_1b,ready_2b};
    
always_comb begin
d_state = q_state;
d_count = q_count;
d_sel   = q_sel;
data_out_b = 0;
clear_b = 0;
ready_o_b = 0;
valid_i_b = 0;
write_cmt0_b = 0;

clear_1a = 0;
clear_2a = 0;
clear_1b = 0;
clear_2b = 0;

   case(q_state)
      _IDLE:begin
         if(req_seed_pulse)begin
            d_state = _WAIT;
            d_count = 0;
            d_sel   = 0;
         end
      end
      _WAIT:begin
         if(select > 0)begin
            if(select >= 8)begin
               d_sel = 4'b1000;
            end
            if((select >= 4)&&(select <= 7))begin
               d_sel = 4'b0100;
            end
            if((select == 2)||(select == 3))begin
               d_sel = 4'b0010;
            end
            if(select == 1)begin
               d_sel = 4'b0001;
            end
            d_state = _INITIALIZE;
         end
      end
      _INITIALIZE:begin
         valid_i_b = 1;
         d_count = q_count + 1;
         if(q_count == 0)begin
            data_out_b[63:60] = SHAKE_TYPE;
            data_out_b[59:32] = 'h800000;
            data_out_b[31:0]  = INPUT_SIZE;
         end
         if(q_count == 1)begin
            d_count = 0;
            d_state = _PREPARE;
         end
      end
      _PREPARE:begin
         valid_i_b = 1;
         ready_o_b = 1;
         data_out_b = data_out_regs;
         d_count = q_count + 1;
         if(q_count == B_SIZE)begin
            valid_i_b = 0;
         end
         if(q_count == MAX_COUNT-1)begin
            d_count = 0;
            d_state = _GET;
         end
      end
      _GET:begin
         ready_o_b = 1;
         if(valid_o)begin
            d_count = q_count + 1;
            write_cmt0_b = 1;
            if(q_count == (2*(LAMBDA/w))-1)begin
               clear_b = 1;
               d_count = 0;
               d_state = _RESET;
            end
         end
      end
      _RESET:begin
         d_count = q_count + 1;
         if(q_count == 4)begin
            d_count = 0;
            d_state = _CHECK;
            case(q_sel)
               4'b1000: clear_1a = 1;
               4'b0100: clear_2a = 1;
               4'b0010: clear_1b = 1;
               4'b0001: clear_2b = 1;
            endcase
         end
      end
      _CHECK:begin
         if(flag)begin
            d_state = _IDLE;
         end else begin
            d_state = _WAIT;
         end
      end
      default:begin
         d_state = _IDLE;
      end
   endcase
end   
      
always_comb begin
access_1a = (((q_sel == 8)&&(valid_i_b))&&(ready_o_b));
access_2a = (((q_sel == 4)&&(valid_i_b))&&(ready_o_b));
access_1b = (((q_sel == 2)&&(valid_i_b))&&(ready_o_b));
access_2b = (((q_sel == 1)&&(valid_i_b))&&(ready_o_b));
end 

always_comb begin
data_out_regs = 0;
   case(q_sel)
      4'b1000: data_out_regs = comp_data_1a;
      4'b0100: data_out_regs = comp_data_2a;
      4'b0010: data_out_regs = comp_data_1b;
      4'b0001: data_out_regs = comp_data_2b;
      default: data_out_regs = 0;
   endcase
end 

endmodule