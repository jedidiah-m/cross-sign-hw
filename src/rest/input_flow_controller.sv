`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module input_flow_controller(
    input  logic clk,
    input  logic rst,
    input  logic pulse,
    input  logic occupied,
    output logic request,
    output logic [w-1:0]data_out
    );
logic [3:0]q_count,d_count;
logic [4:0]q_address,d_address;
typedef enum logic [3:0] {
        _IDLE,
        _ENTER_SECRET_KEY,
        _WAIT1,
        _ENTER_SEED_SALT,
        _WAIT2,
        _ENTER_MSG_HEADER,
        _STALL,
        _ENTER_MSG,
        _WAIT
    }state_t;
state_t q_state, d_state;
logic [w-1:0] inputs[0:(5*LAMBDA_BLOCKS + 5)];

always_ff @(posedge clk) begin
   if(rst)begin
      q_state <= _IDLE;
      q_address <= 0;
      q_count <= 0;
   end else begin
      q_state <= d_state;
      q_address <= d_address;
      q_count <= d_count;
   end
end 

always_comb begin
   inputs[0]  <= 64'h7C9935A0B07694AA;
   inputs[1]  <= 64'h0C6D10E4DB6B1ADD;
   inputs[2]  <= 64'h2FD81A25CCB14803;
   inputs[3]  <= 64'h2DCD739936737F2D;
   inputs[4]  <= 64'hB505D7CFAD1B4974;
   inputs[5]  <= 64'h99323C8686325E47;
   inputs[6]  <= 64'h92F267AAFA3F87CA;
   inputs[7]  <= 64'h60D01CB54F29202A;
   
   inputs[8]  <= 64'hEB4A7C66EF4EBA2D;
   inputs[9]  <= 64'hDB38C88D8BC706B1;
   inputs[10] <= 64'hD639002198172A7B;
   inputs[11] <= 64'h1942ECA8F6C001BA;
   
   inputs[12] <= 64'hBC07C06D4B4F0F96;
   inputs[13] <= 64'h1EDE468325F9BB2D;
   inputs[14] <= 64'h055C5B62B347EDA8;
   inputs[15] <= 64'h6AA016E134B3A07F;
   inputs[16] <= 64'h37943FC434E309BC;
   inputs[17] <= 64'h5A254D5B9E54964D;
   inputs[18] <= 64'h85665E8863D7DECA;
   inputs[19] <= 64'hBC9C59FBDDE5CF63;
   
   inputs[20] <= 64'h0000000000000023;
   
   inputs[21] <= 64'hD81C4D8D734FCBFB;
   inputs[22] <= 64'hEADE3D3F8A039FAA;
   inputs[23] <= 64'h2A2C9957E835AD55;
   inputs[24] <= 64'hB22E75BF57BB556A;
   inputs[25] <= 64'hC800800000000000;//the hash domain separation constant is appended to the message in little endian byte order (0080)
end

always_comb begin
   d_state = q_state;
   d_count = q_count;
   request = 0;
   case(q_state)
        _IDLE:begin
           if(pulse)
              d_state = _ENTER_SECRET_KEY;
        end
        _ENTER_SECRET_KEY:begin
           request = 1;
           d_count = q_count + 1;
           if(q_count == 2*LAMBDA_BLOCKS-1)begin
              d_count = 0;
              d_state = _WAIT1;
           end
        end
        _WAIT1:begin
           if(occupied == 0)begin
              d_state = _ENTER_SEED_SALT;
           end
        end
        _ENTER_SEED_SALT:begin
           request = 1;
           d_count = q_count + 1;
           if(q_count == 3*LAMBDA_BLOCKS-1)begin
              d_count = 0;
              d_state = _WAIT2;
           end
        end
        _WAIT2:begin
           if(occupied == 0)begin
              d_state = _ENTER_MSG_HEADER;
           end  
        end
        _ENTER_MSG_HEADER:begin
           request = 1;
           d_state = _STALL;
        end
        _STALL:begin
           d_state = _ENTER_MSG;
        end
        _ENTER_MSG:begin
           request = 1;
           d_count = q_count + 1;
           if(q_count == 4)begin
              d_count = 0;
              d_state = _WAIT;
           end   
        end
        _WAIT:begin
        end
        default:begin
           d_state = _IDLE;
        end
   endcase
end

always_comb begin
   d_address = q_address;
   if(request)begin
      d_address = q_address + 1;
      if(q_address == 5*LAMBDA_BLOCKS + 5)begin
         d_address = 0;
      end
   end
end
    
assign data_out = inputs[q_address];
    
endmodule