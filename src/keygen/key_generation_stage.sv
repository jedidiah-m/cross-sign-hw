`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;
//part_of_sign
module key_generation_stage(
    input  logic clk,
    input  logic rst,
    input  logic shift_seed_sk,
    input  logic[w-1:0] data_system,
    output logic finished_ebar,
    output logic write_ebar,
    output logic [16*Z_BIT_WIDTH-1:0] place_ebar,
    output logic finished_vt,
    output logic write_vt,
    output logic [16*P_BIT_WIDTH-1:0] place_vt,
    //connect to shake
    output  logic ready_o,
    output  logic valid_i,
    output  logic clear_in,
    input  logic ready_i,
    input  logic valid_o,
    output logic[w-1:0] data_i,
    input logic[w-1:0] data_o
    );
    

logic [w-1:0] data_controller,data_vt,data_e,datask,sk,pk;
logic [2:0] select_input;
logic rotate_seed_sk,system_ready_o,shift_seed_vt,rotate_seed_vt,shift_seed_e,rotate_seed_e,valid_o_e,valid_o_vt;
logic rotate_seedsk,rotate_seedvt,valid_input,valid_oe,valid_ovt,clear_by_system;

function logic [w-1:0] quad_switch(input logic [w-1:0] x);
      logic [w-1:0] result;
      for (int i = 0; i < 8; i++) begin
         for (int j = 0; j < 8; j++) begin
            result[(8*i + j)] = x[(8*(i+1) - 1)-j];
         end
      end
      return result;
endfunction


//keccak shake_unit(
//        .clk (clk),
//        .rst (rst),
//        .clear_in (clear_in),
//        .ready_o (!ready_o),
//        .valid_i (!valid_i),
//        .ready_i (ready_i),
//        .valid_o (valid_o),
//        .data_i (data_i),
//        .data_o (data_o)
//);
    
keygen_controller ctrl(
        .clk (clk),
        .reset (rst),
        .shift_seed_sk (shift_seed_sk),
        .valid_o (valid_o),
        .finished_ebar (finished_ebar),
        .finished_vt (finished_vt),
        .valid_input (valid_input),
        .rotate_seed_sk (rotate_seed_sk),
        .data_out (data_controller),
        .select_input (select_input),
        .system_ready_o (system_ready_o),
        .shift_seed_vt (shift_seed_vt),
        .rotate_seed_vt (rotate_seed_vt),
        .shift_seed_e (shift_seed_e),
        .rotate_seed_e (rotate_seed_e),
        .valid_o_e (valid_o_e),
        .valid_o_vt (valid_o_vt),
        .clear_by_system (clear_by_system)
);

sampler_vt matrix(
        .clk (clk),
        .rst (rst),
        .data_in (quad_switch(data_o)),
        .valid_o (valid_ovt),
        .interrupt (interrupt_vt),
        .finished (finished_vt),
        .write_out (write_vt),
        .place_memory (place_vt)
);

sampler_ebar vector(
        .clk (clk),
        .rst (rst),
        .data_in (quad_switch(data_o)),
        .valid_o (valid_oe),
        .interrupt (interrupt_e),
        .finished (finished_ebar),
        .write_out (write_ebar),
        .place_memory (place_ebar)
);

pad_generator storesk(
        .clk (clk),
        .reset (rst),
        .shift (shift_seed_sk),
        .rotate (rotate_seedsk),
        .data_in (data_system),
        .data_out (datask)
);

pad_generator storeseedvt(
        .clk (clk),
        .reset (rst),
        .shift (shift_seed_vt),
        .rotate (rotate_seedvt),
        .data_in (data_o),
        .data_out (data_vt)
);

pad_generator storeseedebar(
        .clk (clk),
        .reset (rst),
        .shift (shift_seed_e),
        .rotate (rotate_seed_e),
        .data_in (data_o),
        .data_out (data_e)
);

assign sk = datask;
assign pk = data_vt;

always_comb begin
   case(select_input)
       3'b000 : data_i = 0;
       3'b001 : data_i = data_controller;
       3'b010 : data_i = datask;
       3'b011 : data_i = data_vt;
       3'b100 : data_i = data_e;
       default  data_i = 0;
   endcase
end
    
assign rotate_seedsk = rotate_seed_sk;
assign rotate_seedvt = rotate_seed_vt;
assign ready_o = system_ready_o & (!interrupt_e) & (!interrupt_vt);
assign clear_in = finished_ebar | finished_vt | clear_by_system;
assign valid_i = valid_input;
assign valid_oe = valid_o_e & valid_o;
assign valid_ovt = valid_o_vt & valid_o;

endmodule
