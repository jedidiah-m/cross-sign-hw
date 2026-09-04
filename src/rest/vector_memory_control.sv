`timescale 1ns / 1ps

import rsdp_pkg::*;

module vector_memory_control#(
    parameter int INDX = 0,
    parameter int DATA_WIDTH = Z_BIT_WIDTH
)(
    input  logic clk,
    input  logic rst,
    input  logic write,
    input  logic req,
    input  logic [16*DATA_WIDTH-1:0] data_in,
    output logic [12:0] del_address,
    output logic del_write,
    output logic [16*DATA_WIDTH-1:0] del_data_in,
    output logic rsp
    );
    
localparam int ENTRY = ((N_VEC)/16)+1;
localparam int MAX_ADDRESS_WRITE = LEAVES[INDX]*ENTRY - 1;
localparam int MAX_ADDRESS_READ  = LEAVES[0]*ENTRY - 1;

logic d_write,d_req,del_req;
logic [2:0] d_rsp, q_rsp;
logic [16*DATA_WIDTH-1:0] d_data_in;
logic [12:0] d_waddress,d_raddress,q_waddress,q_raddress,address;

always_ff @(posedge clk) begin
   if(rst)begin
      q_waddress <= 0;
      q_raddress <= 0;
      q_rsp      <= 0;
   end else begin
      q_waddress <= d_waddress;
      q_raddress <= d_raddress;
      q_rsp      <= d_rsp;
   end
end

regn #(
    .WIDTH(16*DATA_WIDTH + 2)
) delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({req,   write,   data_in  }),
    .data_o ({d_req, d_write, d_data_in})
);

always_comb begin
   d_raddress = q_raddress;
   d_waddress = q_waddress;
   if(d_write)begin
      d_waddress = q_waddress + 1;
      if(q_waddress == MAX_ADDRESS_WRITE)begin
         d_waddress = 0;
      end
   end else if(d_req)begin
      d_raddress = q_raddress + 1;
      if(q_raddress == MAX_ADDRESS_READ)begin
         d_raddress = 0;
      end
   end
end

always_comb begin
   address = 0;
   if(d_write)begin
      address = q_waddress;
   end else if(d_req)begin
      address = q_raddress;
   end
end

regn #(
    .WIDTH(16*DATA_WIDTH + 15)
) sec_delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({d_req,   d_write,   address,     d_data_in  }),
    .data_o ({del_req, del_write, del_address, del_data_in})
);
    
assign d_rsp = {q_rsp,del_req};   

assign rsp         = q_rsp[2];  
    
endmodule