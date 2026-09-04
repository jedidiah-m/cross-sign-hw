`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module ch2_sampler(
    input  logic clk,
    input  logic rst,
    input  logic interrupt,
    input  logic restart,
    input  logic increment,
    input  logic [9:0] bit_counter,
    input  logic [9:0] candidate_pos,
    output logic clr,
    output logic shift_coeff,
    output logic [3:0] bits_required,
    //output logic rearr,
    output logic challenge
    );
    
logic [8:0] wa,ra;
logic [9:0] q_curr,d_curr,q_dest,d_dest;
logic wdata,rdata,q_rdata,d_rdata;
logic write;
logic q_temp,d_temp,w_temp;
logic [8:0] q_address,d_address;
logic valid,rearr;
logic [2:0] q_timeout,d_timeout;
typedef enum logic [1:0] {
        RESET,
        CLEAR,
        SHUFFLE,
        READ
    } state_t;
state_t q_state, d_state;
    
chall_string storage(
  .clk   (clk),
  .rst   (rst),
  .wa    (wa),
  .wdata (wdata),
  .ra    (ra),
  .write (write),
  .rearr (rearr),
  .rdata (rdata)
);

always_ff @(posedge clk) begin
   if(rst)begin
      q_state   <= RESET;
      q_temp    <= '0;
      q_timeout <= '0;
      q_address <= '0;
      q_curr    <= '0;
      q_dest    <= '0;
      q_rdata   <= '0;
   end else begin
      q_state   <= d_state;
      q_temp    <= d_temp;
      q_timeout <= d_timeout;
      q_address <= d_address;
      q_curr    <= d_curr;
      q_dest    <= d_dest;
      q_rdata   <= d_rdata;
   end
end

assign d_temp = (w_temp) ? q_rdata : q_temp;
assign d_rdata = rdata;
assign challenge = q_rdata;
assign shift_coeff = interrupt&(q_timeout==0)&(!clr)&(bits_required <= bit_counter);
assign valid = shift_coeff&(candidate_pos < T_VEC - q_address)&(!clr);


always_comb begin
   d_curr    = q_curr;
   d_dest    = q_dest;
   if(valid)begin
      d_curr    = q_address;
      d_dest    = candidate_pos;
   end
end
    
always_comb begin
   d_timeout = q_timeout;
   if((valid)||(q_timeout>0))begin
      d_timeout = q_timeout+1;
      if(q_timeout == 4)
         d_timeout = 0;
   end
end

always_comb begin
   bits_required = 0;
   casez (T_VEC - 1 - q_address)
      9'b00000000? : bits_required = 1;
      9'b00000001? : bits_required = 2;
      9'b0000001?? : bits_required = 3;
      9'b000001??? : bits_required = 4;
      9'b00001???? : bits_required = 5;
      9'b0001????? : bits_required = 6;
      9'b001?????? : bits_required = 7;
      9'b01??????? : bits_required = 8;
      9'b1???????? : bits_required = 9;
      default : bits_required = 0;
   endcase
end

always_comb begin
   d_state   = q_state;
   d_address = q_address;
   clr   = 0;
   wa    = 0;
   ra    = 0;
   wdata = 0;
   write = 0;
   w_temp= 0;
   rearr = 0;
   case(q_state)
      RESET  :begin
         d_address = 0;
         d_state   = SHUFFLE;
      end
      SHUFFLE:begin
         case (q_timeout)
            0:begin
               if(q_address == T_VEC)begin
                  clr = 1;
                  d_address = 0;
                  d_state = READ;
               end
               if(valid)begin
                  d_address = q_address + 1;
               end
            end 
            1:begin
               ra     = q_curr;
            end
            2:begin
               ra    = q_dest + q_curr;
               w_temp = 1;
            end
            3:begin
               write  = 1;
               wa     = q_curr;
               wdata  = q_rdata;
            end
            4:begin
               write  = 1;
               wa     = q_dest + q_curr;
               wdata  = q_temp;
            end
         endcase
      end
      READ   :begin
         ra    = q_address;
         if(increment)begin
            d_address = q_address +1;
            if(q_address == T_VEC-1)begin
               d_address = 0;
            end
         end 
         else if(restart) begin
            d_address = 0;
            d_state = SHUFFLE;
            rearr = 1;
         end
      end
   endcase
end
    
endmodule
