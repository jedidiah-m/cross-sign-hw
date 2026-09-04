`timescale 1ns / 1ps

import rsdp_pkg::*;

module memory_e_bar #(
    parameter int DATA_WIDTH = Z_BIT_WIDTH
)(
    input  logic clk,
    input  logic rst,
    input  logic write_ebar,
    input  logic write_vt,
    input  logic [16*DATA_WIDTH-1:0] place_ebar,
    input  logic finished_vt,
    output logic mode,
    output logic shift_single,
    output logic [16*DATA_WIDTH-1:0] array_add,
    output logic [DATA_WIDTH-1:0] e_bar_mul
    );
    
localparam int FRAC = N_VEC % 16;
localparam int INPTS = N_VEC / 16;
localparam int NO_ADD = (N_VEC - K_VEC) / 16;
localparam int NO_ADD_FRAC = (N_VEC - K_VEC) % 16;
    
logic [N_VEC*DATA_WIDTH-1:0] q_array,d_array;
logic [4:0] q_counter,d_counter,q_counter1,d_counter1,q_input_c,d_input_c;
logic mde;

 always_ff @(posedge clk) begin
    if(rst)begin
       q_array <= 0;
       q_counter <= 0;
       q_counter1 <= 0;
       q_input_c <= 0;
    end else begin
       q_array <= d_array;
       q_counter <= d_counter;
       q_counter1 <= d_counter1;
       q_input_c <= d_input_c;
    end
 end
 
 always_comb begin
    d_array = q_array;
    if((write_ebar)&&(!shift_single)&&(!mde))begin
    d_array = {q_array[(N_VEC-16)*DATA_WIDTH-1 : 0],place_ebar};
       if(q_input_c == INPTS)begin
       d_array = {q_array[(N_VEC-FRAC)*DATA_WIDTH-1 : 0],place_ebar[16*DATA_WIDTH-1 -: (FRAC*DATA_WIDTH)]}; 
       end
    end
    if((!write_ebar)&&(shift_single)&&(!mde))begin
       d_array = {q_array[(N_VEC-1)*DATA_WIDTH-1 : 0],q_array[N_VEC*DATA_WIDTH-1 -: DATA_WIDTH]};
    end
    if((!write_ebar)&&(!shift_single)&&(mde))begin
       d_array = {q_array[(N_VEC-16)*DATA_WIDTH-1 : 0],q_array[N_VEC*DATA_WIDTH-1 -: (16*DATA_WIDTH)]};
       if(q_counter == NO_ADD + 1)begin
         d_array = {q_array[(N_VEC-NO_ADD_FRAC)*DATA_WIDTH-1 : 0],q_array[N_VEC*DATA_WIDTH-1 -: (NO_ADD_FRAC*DATA_WIDTH)]};
       end
    end
 end
 
always_comb begin
   d_counter = q_counter;
   mde = 0;
   if(finished_vt)begin
      d_counter = q_counter + 1;
   end
   if(q_counter >= 1)begin
      d_counter = q_counter + 1;
      mde = 1;
      if(q_counter == NO_ADD + 1)begin
         d_counter = 0;
      end
   end
end

always_comb begin
   d_input_c = q_input_c;
   if(write_ebar)begin
      d_input_c = q_input_c + 1;
      if(q_input_c == INPTS)begin
         d_input_c = 0;
      end
   end
end

always_comb begin
   d_counter1 = q_counter1;
   shift_single = 0;
   if(write_vt)begin
      d_counter1 = q_counter1 + 1;
      if(q_counter1 == NO_ADD)begin
         shift_single = 1;
         d_counter1 = 0;
      end
   end
end
 
assign mode = mde;
//assign array_add = q_array[N_VEC*DATA_WIDTH-1 -: 16*DATA_WIDTH];
assign e_bar_mul = q_array[N_VEC*DATA_WIDTH-1 -: DATA_WIDTH];

always_comb begin
   array_add = q_array[N_VEC*DATA_WIDTH-1 -: 16*DATA_WIDTH];
   if(q_counter == NO_ADD + 1)begin
      array_add[16*DATA_WIDTH-1 -: NO_ADD_FRAC*DATA_WIDTH] = q_array[N_VEC*DATA_WIDTH-1 -: NO_ADD_FRAC*DATA_WIDTH];
      array_add[(16-NO_ADD_FRAC)*DATA_WIDTH-1 : 0] = 0;
   end 
end

endmodule
