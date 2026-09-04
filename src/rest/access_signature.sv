`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module access_signature(
    input  logic clk,
    input  logic rst,
    input  logic request,
    input  logic write_sig,
    input  logic write_cmt0_signature,
    input  logic write_cmt1_signature,
    input  logic write_yv_signature,
    input  logic [w-1:0]signature,
    input  logic [w-1:0]data_out_sec,
    input  logic [w-1:0]data_out_cmt_mem,
    input  logic [w-1:0]written_response,
    output logic write_to_signature_a,
    output logic [13:0]address_signature_a,
    output logic [w-1:0]data_in_signature_a,
    output logic write_to_signature_b,
    output logic [13:0]address_signature_b,
    output logic [w-1:0]data_in_signature_b,
    output logic response
    );

localparam int SIGNATURE_HEADER_START = 0;
localparam int SIGNATURE_HEADER_DURATION = 6*LAMBDA_BLOCKS + W_VEC*LAMBDA_BLOCKS;

localparam int PROOF_START = 6*LAMBDA_BLOCKS + W_VEC*LAMBDA_BLOCKS;
localparam int PROOF_DURATION = 2*W_VEC*LAMBDA_BLOCKS;

localparam int RESP1_START = 6*LAMBDA_BLOCKS + W_VEC*LAMBDA_BLOCKS + 2*W_VEC*LAMBDA_BLOCKS;
localparam int RESP1_DURATION = 2*(T_VEC-W_VEC)*LAMBDA_BLOCKS;

localparam int RESP0_START = 6*LAMBDA_BLOCKS + W_VEC*LAMBDA_BLOCKS + 2*W_VEC*LAMBDA_BLOCKS + 2*(T_VEC-W_VEC)*LAMBDA_BLOCKS;
localparam int RESP0_DURATION = SIG_SIZE - RESP0_START;

logic write_port_a,d_write_port_a;
logic [13:0]address_port_a,d_address_port_a;
logic [w-1:0]data_in_port_a,d_data_in_port_a;

logic write_port_b,d_write_port_b;
logic [13:0]address_port_b,d_address_port_b;
logic [w-1:0]data_in_port_b,d_data_in_port_b;

logic d_request,dd_request;
logic d_write_sig;
logic d_write_cmt0_signature;
logic d_write_cmt1_signature;
logic d_write_yv_signature;
logic [w-1:0]d_signature;
logic [w-1:0]d_data_out_sec;
logic [w-1:0]d_data_out_cmt_mem;
logic [w-1:0]d_written_response;

logic [2:0]ctrl_port_a,q_rsp,d_rsp;
logic [1:0]ctrl_port_b;

logic [13:0]q_count0,q_count1,q_count2,q_count3,d_count0,d_count1,d_count2,d_count3,q_address,d_address,count_0,count_1,count_2,count_3;

regn #(
    .WIDTH(4*w + 5)
)input_delay(
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({request  ,write_sig,  write_cmt0_signature,  write_cmt1_signature,  write_yv_signature,  signature,  data_out_sec,  data_out_cmt_mem,  written_response  }),
    .data_o ({d_request,d_write_sig,d_write_cmt0_signature,d_write_cmt1_signature,d_write_yv_signature,d_signature,d_data_out_sec,d_data_out_cmt_mem,d_written_response})
);

always_ff @(posedge clk)begin
   if(rst)begin
      q_count0  <= 0; 
      q_count1  <= 0;
      q_count2  <= 0;
      q_count3  <= 0;
      q_address <= 0;
      q_rsp     <= 0;
   end else begin
      q_count0  <= d_count0;
      q_count1  <= d_count1;
      q_count2  <= d_count2;
      q_count3  <= d_count3;
      q_address <= d_address;
      q_rsp     <= d_rsp;
   end
end

assign ctrl_port_a = {d_request,d_write_sig,d_write_cmt1_signature};
assign ctrl_port_b = {d_write_cmt0_signature,d_write_yv_signature};
                    
always_comb begin
   d_count0 = q_count0;
   if(d_write_sig)begin
      d_count0 = q_count0 + 1;
      if(q_count0 == SIGNATURE_HEADER_DURATION - 1)begin
         d_count0 = 4*LAMBDA_BLOCKS;
      end
   end
end

assign count_0 = q_count0 + SIGNATURE_HEADER_START;

always_comb begin
   d_count1 = q_count1;
   if(d_write_cmt0_signature)begin
      d_count1 = q_count1 + 1;
      if(q_count1 == PROOF_DURATION - 1)begin
         d_count1 = 0;
      end
   end
end

assign count_1 = q_count1 + PROOF_START;

always_comb begin
   d_count2 = q_count2;
   if(d_write_cmt1_signature)begin
      d_count2 = q_count2 + 1;
      if(q_count2 == RESP1_DURATION - 1)begin
         d_count2 = 0;
      end
   end
end

assign count_2 = q_count2 + RESP1_START;

always_comb begin
   d_count3 = q_count3;
   if(d_write_yv_signature)begin
      d_count3 = q_count3 + 1;
      if(q_count3 == RESP0_DURATION - 1)begin
         d_count3 = 0;
      end
   end
end

assign count_3 = q_count3 + RESP0_START;

always_comb begin
   d_address = q_address;
   if(d_request)begin
      d_address = q_address + 1;
      if(q_address == SIG_SIZE - 1)begin
         d_address = 0;
      end
   end
end
   
always_comb begin
   write_port_a = 0;
   address_port_a = q_address;
   data_in_port_a = 0;
   case(ctrl_port_a)
       3'b100:begin
          address_port_a = q_address;
       end
       3'b010:begin
          write_port_a = 1;
          address_port_a = count_0;
          data_in_port_a = d_signature;
       end
       3'b001:begin
          write_port_a = 1;
          address_port_a = count_2;
          data_in_port_a = d_data_out_sec;
       end
   endcase
end

always_comb begin
   write_port_b = 0;
   address_port_b = 0;
   data_in_port_b = 0;
   case(ctrl_port_b)
       2'b10:begin
          write_port_b = 1;
          address_port_b = count_1;
          data_in_port_b = d_data_out_cmt_mem;
       end
       2'b01:begin
          write_port_b = 1;
          address_port_b = count_3;
          data_in_port_b = d_written_response;
       end
   endcase
end

regn #(
    .WIDTH(2*w + 31)
)output_delay(
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({d_request,  write_port_a,   address_port_a,   data_in_port_a,   write_port_b,   address_port_b,   data_in_port_b  }),
    .data_o ({dd_request, d_write_port_a, d_address_port_a, d_data_in_port_a, d_write_port_b, d_address_port_b, d_data_in_port_b})
);

assign d_rsp = {q_rsp,dd_request};
assign response = q_rsp[2];
assign write_to_signature_a = d_write_port_a;
assign address_signature_a = d_address_port_a;
assign data_in_signature_a = d_data_in_port_a;
assign write_to_signature_b = d_write_port_b;
assign address_signature_b = d_address_port_b;
assign data_in_signature_b = d_data_in_port_b;
    
endmodule