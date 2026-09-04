`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sig_process_mem_control(
    input  logic clk,
    input  logic rst,
    input  logic write_seed,
    input  logic write_cmt0,
    input  logic write_cmt1,
    input  logic write_v,
    input  logic write_y,
    input  logic [w-1:0]seed,
    input  logic [w-1:0]cmt0,
    input  logic [w-1:0]cmt1,
    input  logic [w-1:0]v,
    input  logic [w-1:0]y,
    input  logic req,
    input  logic [14:0] raddress,
    output logic [w-1:0] data_out,
    output logic rsp,
    ///convert to dual port
    input  logic req_sec,
    input  logic [14:0] raddress_sec,
    output logic [w-1:0] data_out_sec,
    output logic rsp_sec
    );
    
localparam int SEED_INITIAL_ADD = 0; 
localparam int SEED_DURATION = ((LAMBDA/w)*T_VEC); 

localparam int CMT0_INITIAL_ADD = ((LAMBDA/w)*T_VEC); 
localparam int CMT0_DURATION = (((2*LAMBDA)/w)*T_VEC); 

localparam int CMT1_INITIAL_ADD = (((3*LAMBDA)/w)*T_VEC);    
localparam int CMT1_DURATION = (((2*LAMBDA)/w)*T_VEC); 

localparam int V_INITIAL_ADD = (((5*LAMBDA)/w)*T_VEC); 
localparam int V_DURATION = V_SIZE * T_VEC;

localparam int Y_INITIAL_ADD = (((5*LAMBDA)/w)*T_VEC) + (V_SIZE * T_VEC); 
localparam int Y_DURATION = Y_SIZE * T_VEC;

logic d_write_seed, d_write_cmt0, d_write_cmt1, d_write_v, d_write_y, d_req, write, del_write, del_req, d_req_sec, dd_req_sec;
logic [4:0] comb, wr;
logic [2:0] d_rsp, q_rsp,d_rsp_sec,q_rsp_sec;
logic [14:0] d_raddress,q0,d0,q1,d1,q2,d2,q3,d3,q4,d4,w_address,address,del_address, d_raddress_sec, dd_raddress_sec;
logic [w-1:0] d_data_in,del_data_in,data_in;

assign wr = {write_seed,   write_cmt0,   write_cmt1,   write_v,   write_y};

always_comb begin
   data_in = 0;
   case(wr)
      5'b10000 : data_in = seed;
      5'b01000 : data_in = cmt0;
      5'b00100 : data_in = cmt1;
      5'b00010 : data_in = v;
      5'b00001 : data_in = y;
      default : data_in = 0;
   endcase
end

regn #(
    .WIDTH(w + 21)
) delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({req,   write_seed,   write_cmt0,   write_cmt1,   write_v,    write_y,    raddress,   data_in  }),
    .data_o ({d_req, d_write_seed, d_write_cmt0, d_write_cmt1, d_write_v,  d_write_y,  d_raddress, d_data_in})
);

regn #(
    .WIDTH(16)
) delay_sec (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({req_sec,   raddress_sec  }),
    .data_o ({d_req_sec, d_raddress_sec })
);

always_ff @(posedge clk) begin
   if(rst)begin
      q0 <= 0;
      q1 <= 0;
      q2 <= 0;
      q3 <= 0;
      q4 <= 0;
      q_rsp <= 0;
      q_rsp_sec <= 0;
   end else begin
      q0 <= d0;
      q1 <= d1;
      q2 <= d2;
      q3 <= d3;
      q4 <= d4;
      q_rsp <= d_rsp;
      q_rsp_sec <= d_rsp_sec;
   end
end

assign write = (d_write_seed)|(d_write_cmt0)|(d_write_cmt1)|(d_write_v)|(d_write_y); 
assign comb = {d_write_seed,d_write_cmt0,d_write_cmt1,d_write_v,d_write_y};

always_comb begin 
   d0 = q0;
   if(comb == 5'b10000)begin
      d0 = q0 + 1;
      if(q0 == SEED_DURATION - 1)begin
         d0 = 0;
      end
   end
end

always_comb begin 
   d1 = q1;
   if(comb == 5'b01000)begin
      d1 = q1 + 1;
      if(q1 == CMT0_DURATION - 1)begin
         d1 = 0;
      end
   end
end

always_comb begin 
   d2 = q2;
   if(comb == 5'b00100)begin
      d2 = q2 + 1;
      if(q2 == CMT1_DURATION - 1)begin
         d2 = 0;
      end
   end
end

always_comb begin 
   d3 = q3;
   if(comb == 5'b00010)begin
      d3 = q3 + 1;
      if(q3 == V_DURATION - 1)begin
         d3 = 0;
      end
   end
end

always_comb begin 
   d4 = q4;
   if(comb == 5'b00001)begin
      d4 = q4 + 1;
      if(q4 == Y_DURATION - 1)begin
         d4 = 0;
      end
   end
end

always_comb begin
   w_address = 0;
   case(comb)
      5'b10000 : w_address = q0 + SEED_INITIAL_ADD;
      5'b01000 : w_address = q1 + CMT0_INITIAL_ADD;
      5'b00100 : w_address = q2 + CMT1_INITIAL_ADD;
      5'b00010 : w_address = q3 + V_INITIAL_ADD;
      5'b00001 : w_address = q4 + Y_INITIAL_ADD;
      default : w_address = 0;
   endcase
end

always_comb begin
   address = 0;
   if(write)begin
      address = w_address;
   end else if(d_req)begin
      address = d_raddress;
   end
end

regn #(
    .WIDTH(w + 17)
) second_delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({write,     address,     d_data_in,   d_req  }),
    .data_o ({del_write, del_address, del_data_in, del_req})
);

regn #(
    .WIDTH(16)
) second_delay_sec (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({d_req_sec,   d_raddress_sec }),
    .data_o ({dd_req_sec,  dd_raddress_sec})
);

sig_process_mem_select mem(
    .clka  (clk),
    .addra (del_address),
    .dina  (del_data_in),
    .wea   (del_write),
    .douta (data_out),
    .clkb  (clk),
    .addrb (dd_raddress_sec),
    .dinb  (0),
    .web   (0),
    .doutb (data_out_sec)
    );
assign d_rsp = {q_rsp,del_req};   
assign rsp = q_rsp[2];
assign d_rsp_sec = {q_rsp_sec,dd_req_sec};
assign rsp_sec = q_rsp_sec[2];
endmodule