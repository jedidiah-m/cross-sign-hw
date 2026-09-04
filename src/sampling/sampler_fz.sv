`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sampler_fz(
    input  logic clk,
    input  logic reset,
    input  logic valid_o,
    input  logic finished,
    input  logic [3*Z_BIT_WIDTH-1:0] data_in,
    
    output  logic shift_serial,
    output  logic valid_serial,
    output  logic [Z_BIT_WIDTH-1:0] data_serial,
    output  logic shift_parallel,
    output  logic valid_parallel,
    output  logic [3*Z_BIT_WIDTH-1:0] data_parallel,
    output  logic interrupt
    );
    
logic serial_correct,parallel_correct;
logic [7:0] q_fifo_count,d_fifo_count;
logic d_interrupt,q_interrupt;

function logic [Z_BIT_WIDTH-1:0] tripple_bit_switch(input logic [Z_BIT_WIDTH-1:0] x);
      logic [Z_BIT_WIDTH-1:0] result;
      for (int i = 0; i < Z_BIT_WIDTH; i++) begin
        result[i] = x[Z_BIT_WIDTH - 1 - i];
      end
      return result;
endfunction
    
   always_ff @(posedge clk)begin
        if(reset)begin
            q_fifo_count <= 0;
            q_interrupt  <= 0;
        end else begin
            q_fifo_count <= d_fifo_count;
            q_interrupt  <= d_interrupt;
        end
    end
    
//counter
    always_comb begin
       d_fifo_count = q_fifo_count;
       if(finished)begin
              d_fifo_count = 0;
        end else begin 
           if((valid_o) && (!shift_serial) && (!shift_parallel))begin 
              d_fifo_count = q_fifo_count + 'b1000000;
              if(q_fifo_count > 'b10000000)
                 d_fifo_count = 'b11000000;
           end
           if((!valid_o) && (shift_serial) && (!shift_parallel))begin 
              d_fifo_count = q_fifo_count - 'b11;
              if(q_fifo_count < 'b11)
                 d_fifo_count = 'b0;
           end
           if((!valid_o) && (!shift_serial) && (shift_parallel))begin 
              d_fifo_count = q_fifo_count - 'b1001;
              if(q_fifo_count < 'b1001)
                 d_fifo_count = 'b0;
           end
        end
    end
    
//fifofull
    assign interrupt = q_interrupt;
    always_comb begin
       d_interrupt = q_interrupt;
       if(q_fifo_count == 0)begin
          d_interrupt = 0;
       end
       if(q_fifo_count == 'b10000000)begin
          d_interrupt = 1;
       end
    end
  
//serial parallel correct
    always_comb begin
       serial_correct = 1;
       if(data_in[3*Z_BIT_WIDTH-1:2*Z_BIT_WIDTH] == 3'b111)
          serial_correct = 0;
    end
    
    always_comb begin
       parallel_correct = 1;
       if(data_in[3*Z_BIT_WIDTH-1:2*Z_BIT_WIDTH] == 3'b111)
          parallel_correct = 0;
       if(data_in[2*Z_BIT_WIDTH-1:Z_BIT_WIDTH] == 3'b111)
          parallel_correct = 0;
       if(data_in[Z_BIT_WIDTH-1:0] == 3'b111)
          parallel_correct = 0;
    end
    
    
//shift valid for each output
    always_comb begin
       shift_serial = 0;
       shift_parallel = 0;
       valid_serial = 0;
       valid_parallel = 0;
       if(q_interrupt)begin
          if((q_fifo_count < 'b1001) && (q_fifo_count > 0))begin
             shift_serial = 1;
             if(serial_correct)
                valid_serial = 1;
          end else if(q_fifo_count >= 'b1001)begin
             if(parallel_correct)begin
                shift_parallel = 1;
                valid_parallel = 1;
             end else begin
                shift_serial = 1;
                if(serial_correct)
                   valid_serial = 1;
             end
          end
       end
    end
    
//assign outputs
    assign data_serial = tripple_bit_switch(data_in[3*Z_BIT_WIDTH-1:2*Z_BIT_WIDTH]);
    assign data_parallel[3*Z_BIT_WIDTH-1:2*Z_BIT_WIDTH] = tripple_bit_switch(data_in[3*Z_BIT_WIDTH-1:2*Z_BIT_WIDTH]);
    assign data_parallel[2*Z_BIT_WIDTH-1:  Z_BIT_WIDTH] = tripple_bit_switch(data_in[2*Z_BIT_WIDTH-1:  Z_BIT_WIDTH]);
    assign data_parallel[  Z_BIT_WIDTH-1:            0] = tripple_bit_switch(data_in[  Z_BIT_WIDTH-1:            0]);
    
endmodule