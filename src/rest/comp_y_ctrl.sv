`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module comp_y_ctrl(
    input  logic clk,
    input  logic rst,
    input  logic write,
    input  logic [w-1:0]data_in,
    input  logic req,
    input  logic [13:0]r_address,
    output logic [13:0] addra,
    output logic [w-1:0] dina,
    output logic wea,
    output logic rsp
    );
    
localparam int MAX_ADDRESS = (SECURITY_LVL == 1) ? 2203:
                             (SECURITY_LVL == 3) ? 5145:
                             (SECURITY_LVL == 5) ? 8836:
                                                   2203;
logic [2:0] d_rsp, q_rsp;
logic [13:0]q_address,d_address,address;

logic d_req;
    
always_ff @(posedge clk) begin
   if(rst)begin
      q_address <= 0;
      q_rsp     <= 0;
   end else begin
      q_address <= d_address;
      q_rsp     <= d_rsp;
   end
end 

always_comb begin
   d_address = q_address;
   address = 0;
   if(write)begin
      address = q_address;
      d_address = q_address + 1;
      if(q_address == MAX_ADDRESS-1)begin
         address = q_address;
         d_address = 0;
      end
   end else if(req)begin
      address = r_address; 
   end
end

regn #(
    .WIDTH(w + 16)
) delay (
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({write, data_in, req,   address}),
    .data_o ({wea,   dina,    d_req, addra  })
);

assign d_rsp = {q_rsp,d_req};   

assign rsp   = q_rsp[2];
    
endmodule