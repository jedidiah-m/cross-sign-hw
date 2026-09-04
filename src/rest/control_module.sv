`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*; 

module control_module(
//figure out the communication protocol
    input  logic clk,
    input  logic rst,
    input  logic write,
    input  logic [w-1:0] data_write,
    
    input  logic [1:0] request,
    input  logic [w-1:0] signature,//slave_module
    input  logic verify,//slave_module
    input  logic occupied,//slave_module
    output logic [w-1:0] data_read,
    
    input  logic ready_in,//slave_module
    output logic ready_out,
    
    //verification inputs
      output logic shift_pk,
      output logic [w-1:0]public_key,
    
      output logic shift_signature_outer,
      output logic [w-1:0]signature_outer,
      
      output logic shift_message_verify,
      output logic [w-1:0] message_verify,
    //sign inputs
      output logic shift_seed_sk,
      output logic [w-1:0] seed_sk,
    
      output logic shift_seed_lambda,
      output logic [w-1:0] seed_lambda,
    
      output logic shift_salt,
      output logic [w-1:0] salt,
      
      output logic shift_message_sign,
      output logic [w-1:0] message_sign
    );

localparam int SECRET_KEY_SIZE = (2*LAMBDA)/w;
localparam int SEED_L_SIZE = (LAMBDA)/w;
localparam int SALT_SIZE = (2*LAMBDA)/w;
localparam int PUBLIC_KEY_SIZE = ((2*LAMBDA)/w) + (((N_VEC - K_VEC)*7)/w) + 1;

typedef enum logic [5:0] {
        IDLE,
        SIGN,
        PUB_KEY,
        DIGEST_M,
        MESSAGE_IN,
        SIG_IN
    } state_t;
state_t q_state, d_state;
int q_input_count, d_input_count, q_max_count, d_max_count, q_opmode, d_opmode;
logic cwrite;

 always_ff @(posedge clk) begin
    if(rst)begin
       q_state <= IDLE;
       q_input_count <= 0;
       q_max_count <= 0;
       q_opmode <= 0;
    end else begin
       q_state <= d_state;
       q_input_count <= d_input_count;
       q_max_count <= d_max_count;
       q_opmode <= d_opmode;
    end
 end

assign ready_out = ready_in;
assign cwrite = (write)&(!occupied);

always_comb begin
   data_read = 0;
   if(request != 0)begin
      if((request == 2'b01)&&(ready_in))begin
         data_read = signature;
      end
      if((request == 2'b10)&&(ready_in))begin
         data_read = verify;
      end
      if((request == 2'b11)&&(ready_in))begin
         data_read = occupied;
      end
   end
end

always_comb begin
d_state = q_state;
d_input_count = q_input_count;
d_max_count = q_max_count;
d_opmode = q_opmode;

shift_pk = 0;
public_key =0;
shift_signature_outer = 0;
signature_outer = 0;
shift_message_verify = 0;
message_verify = 0;
shift_seed_sk = 0;
seed_sk = 0;
shift_seed_lambda = 0;
seed_lambda = 0;
shift_salt = 0;
salt = 0;
shift_message_sign = 0;
message_sign = 0;

    case(q_state)
       IDLE:begin
          if((cwrite)&&(data_write==0))begin
             d_state = SIGN; 
             d_opmode = 0;
             d_max_count = SECRET_KEY_SIZE + SEED_L_SIZE + SALT_SIZE;
             d_input_count = 0;
          end
          if((cwrite)&&(data_write==1))begin
             d_state = PUB_KEY;
             d_opmode = 1; 
             d_max_count = PUBLIC_KEY_SIZE; 
             d_input_count = 0; 
          end
       end
       SIGN:begin
          if(cwrite)begin
             d_input_count = q_input_count + 1;
             if(q_input_count == q_max_count - 1)begin
                d_state = DIGEST_M;  
             end
          end
          if(q_input_count < SECRET_KEY_SIZE)begin
             shift_seed_sk = cwrite;
             seed_sk = data_write;
          end
          if((q_input_count >= SECRET_KEY_SIZE)&&(q_input_count < SECRET_KEY_SIZE + SEED_L_SIZE))begin
             shift_seed_lambda = cwrite;
             seed_lambda = data_write; 
          end 
          if(q_input_count >= SECRET_KEY_SIZE + SEED_L_SIZE)begin
             shift_salt = cwrite;
             salt = data_write;  
          end
       end
       PUB_KEY:begin
          if(cwrite)begin
             d_input_count = q_input_count + 1;
             if(q_input_count == q_max_count - 1)begin
                d_state = DIGEST_M;  
             end
          end
          shift_pk = cwrite;
          public_key = data_write;
       end
       DIGEST_M:begin
          if(cwrite)begin
             d_state = MESSAGE_IN;
             d_input_count = data_write + 2;
             shift_message_sign = 1;
             message_sign[63:60] = SHAKE_TYPE;
             message_sign[58:32] = 2*LAMBDA;
             message_sign[31:0] = (data_write + 2)*8;
             if(q_opmode)begin 
                shift_message_verify = 1;
                d_max_count = SIG_SIZE;
                message_verify[63:60] = SHAKE_TYPE;
                message_verify[58:32] = 2*LAMBDA;
                message_verify[31:0] = (data_write + 2)*8;
             end
          end
       end
       MESSAGE_IN:begin
          if(cwrite)begin
             if(q_input_count > 9)begin
                d_input_count = q_input_count - 8;
                message_sign = data_write;
                if(q_opmode)begin
                   message_verify = data_write;
                end  
             end
             if(q_input_count == 9)begin
                d_input_count = q_input_count - 8;
                message_sign[63:8] = data_write[55:0]; 
                message_sign[7:0] = HASH_CONST[7:0];
                if(q_opmode)begin
                   message_verify[63:8] = data_write[55:0]; 
                   message_verify[7:0] = HASH_CONST[7:0];
                end
             end  
             if(q_input_count == 8)begin
                d_input_count = q_input_count - 8; 
                message_sign[63:16] = data_write[47:0]; 
                message_sign[15:8] = HASH_CONST[7:0];
                message_sign[7:0] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:8] = data_write[47:0]; 
                   message_verify[15:8] = HASH_CONST[7:0];
                   message_verify[7:0] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end
             if(q_input_count == 7)begin
                d_input_count = 0; 
                message_sign[63:24] = data_write[39:0]; 
                message_sign[23:16] = HASH_CONST[7:0];
                message_sign[15:8] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:24] = data_write[39:0]; 
                   message_verify[23:16] = HASH_CONST[7:0];
                   message_verify[15:8] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end  
             if(q_input_count == 6)begin
                d_input_count = 0;
                message_sign[63:32] = data_write[31:0]; 
                message_sign[31:24] = HASH_CONST[7:0];
                message_sign[23:16] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:32] = data_write[31:0]; 
                   message_verify[31:24] = HASH_CONST[7:0];
                   message_verify[23:16] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end  
             if(q_input_count == 5)begin
                d_input_count = 0;
                message_sign[63:40] = data_write[23:0]; 
                message_sign[39:32] = HASH_CONST[7:0];
                message_sign[31:24] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:40] = data_write[23:0]; 
                   message_verify[39:32] = HASH_CONST[7:0];
                   message_verify[31:24] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end
             if(q_input_count == 4)begin
                d_input_count = 0;
                message_sign[63:48] = data_write[15:0]; 
                message_sign[47:40] = HASH_CONST[7:0];
                message_sign[39:32] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:48] = data_write[15:0]; 
                   message_verify[47:40] = HASH_CONST[7:0];
                   message_verify[39:32] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end  
             if(q_input_count == 3)begin
                d_input_count = 0;
                message_sign[63:56] = data_write[7:0]; 
                message_sign[55:48] = HASH_CONST[7:0];
                message_sign[47:40] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:56] = data_write[7:0]; 
                   message_verify[55:48] = HASH_CONST[7:0];
                   message_verify[47:40] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end  
             if(q_input_count == 2)begin
                d_input_count = 0;
                message_sign[63:56] = HASH_CONST[7:0];
                message_sign[55:48] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:56] = HASH_CONST[7:0];
                   message_verify[55:48] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end
             if(q_input_count == 1)begin
                d_input_count = 0;
                message_sign[63:56] = HASH_CONST[15:8];
                d_state = DIGEST_M;
                if(q_opmode)begin
                   message_verify[63:56] = HASH_CONST[15:8];
                   d_state = SIG_IN;
                end
             end
          end
       end
       SIG_IN:begin
          if(cwrite)begin
             d_input_count = q_input_count + 1;
             if(q_input_count == q_max_count - 1)begin
                d_state = DIGEST_M;  
             end
          end
          shift_signature_outer = cwrite;
          signature_outer = data_write;
       end
    endcase
end
endmodule