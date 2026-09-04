`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module signature_generator(
    input  logic clk,
    input  logic rst,
    input  logic shift_data_in,
    input  logic [w-1:0]data_in, 
    input  logic request_signature,
    output logic module_response,
    output logic [w-1:0]valid_signature_out,
    output logic occupied,
    output logic ended
    );
    
logic shift_seed_sk;
logic [w-1:0] data_system;//
logic shift_seed_lambda;
logic [w-1:0] seed_lambda;//
logic shift_salt;
logic [w-1:0] salt;//
logic shift_message;
logic [w-1:0]message;//

logic d_ended,q_ended;
logic[15:0]q_count,d_count;
typedef enum logic [2:0] {
        _ENTER_SK,
        _ENTER_SEED,
        _ENTER_SALT,
        _ENTER_MSG_HEADER,
        _ENTER_MSG,
        _WAIT
    } state_t;
state_t q_state, d_state;

always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _ENTER_SK;
      q_count <= 0;  
      q_ended <= 0;
   end else begin
      q_state <= d_state;
      q_count <= d_count;
      q_ended <= d_ended;
   end
end 

always_comb begin
d_state = q_state;
d_count = q_count;
shift_seed_sk = 0;
data_system = 0;//
shift_seed_lambda = 0;
seed_lambda = 0;//
shift_salt = 0;
salt = 0;//
shift_message = 0;
message = 0;//
d_ended = 0;
   case(q_state)
      _ENTER_SK:begin
         if(shift_data_in&&(!occupied))begin
            d_count = q_count + 1;
            shift_seed_sk = 1;
            data_system = data_in;//
            if(q_count == 2*LAMBDA_BLOCKS-1)begin
               d_count = 0;
               d_state = _ENTER_SEED;
            end
         end
      end
      _ENTER_SEED:begin
         if(shift_data_in&&(!occupied))begin
            d_count = q_count + 1;
            shift_seed_lambda = 1;
            seed_lambda = data_in;//
            if(q_count == LAMBDA_BLOCKS-1)begin
               d_count = 0;
               d_state = _ENTER_SALT;
            end
         end
      end
      _ENTER_SALT:begin
         if(shift_data_in&&(!occupied))begin
            d_count = q_count + 1;
            shift_salt = 1;
            salt = data_in;//
            if(q_count == 2*LAMBDA_BLOCKS-1)begin
               d_count = 0;
               d_state = _ENTER_MSG_HEADER;
            end
         end
      end
      _ENTER_MSG_HEADER:begin
         if(shift_data_in&&(!occupied))begin
            shift_message = 1;
            message = data_in;//
            d_state = _ENTER_MSG;
            d_count = data_in[15:0];
         end
      end
      _ENTER_MSG:begin
         if(shift_data_in&&(!occupied))begin
            d_count = q_count - 8;
            shift_message = 1;
            message = data_in;//
            if(q_count <= 8)begin
               d_count = 0;
               d_state = _WAIT;
            end
         end
      end
      _WAIT:begin
         if(occupied == 0)begin
            d_state = _ENTER_SK;
            d_ended = 1;
         end
      end
      default:begin
         d_state = _ENTER_SK;
      end
   endcase
end

assign ended = q_ended;

sign_top  sign(
    .clk                (clk),
    .rst                (rst),
    .shift_seed_sk      (shift_seed_sk),
    .data_system        (data_system),
    .shift_seed_lambda  (shift_seed_lambda),
    .seed_lambda        (seed_lambda),
    .shift_salt         (shift_salt),
    .salt               (salt),
    .shift_message      (shift_message),
    .message            (message),
    .request_signature  (request_signature),
    .module_response    (module_response),
    .valid_signature_out(valid_signature_out),
    .occupied           (occupied)
    );
    
endmodule