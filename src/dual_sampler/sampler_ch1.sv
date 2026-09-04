`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module sampler_ch1(
    input  logic clk,
    input  logic reset,
    input  logic valid_o,
    input  logic finished,
    input  logic [w-2:0] data_in,
    
    output  logic shift_serial,
    output  logic valid_serial,
    output  logic [P_BIT_WIDTH-1:0] data_serial,
    output  logic shift_parallel,
    output  logic valid_parallel,
    output  logic [9*P_BIT_WIDTH-1:0] data_parallel,
    output  logic interrupt
    );
    
logic serial_correct,parallel_correct;
logic [8:0] q_fifo_count,d_fifo_count;
logic d_interrupt,q_interrupt;

function logic [P_BIT_WIDTH-1:0] seven_bit_switch(input logic [P_BIT_WIDTH-1:0] x);
      logic [P_BIT_WIDTH-1:0] result;
      for (int i = 0; i < P_BIT_WIDTH; i++) begin
        result[i] = x[P_BIT_WIDTH - 1 - i];
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
              if(q_fifo_count > 'b110000000)
                 d_fifo_count = 'b111000000;
           end
           if((!valid_o) && (shift_serial) && (!shift_parallel))begin 
              d_fifo_count = q_fifo_count - 'b111;
              if(q_fifo_count < 'b111)
                 d_fifo_count = 'b0;
           end
           if((!valid_o) && (!shift_serial) && (shift_parallel))begin 
              d_fifo_count = q_fifo_count - 'b111111;
              if(q_fifo_count < 'b111111)
                 d_fifo_count = 'b0;
           end
        end
    end
    
//fifofull
    assign interrupt = q_interrupt;
    always_comb begin
       d_interrupt = q_interrupt;
       if(d_fifo_count == 0)begin
          d_interrupt = 0;
       end
       if(d_fifo_count == 'b111000000)begin
          d_interrupt = 1;
       end
    end
  
//serial parallel correct
    always_comb begin
       serial_correct = 1;
       if(data_in[9*P_BIT_WIDTH-2:8*P_BIT_WIDTH] == 6'b111111)
          serial_correct = 0;
    end
    
    always_comb begin
       parallel_correct = 1;
       if(data_in[9*P_BIT_WIDTH-2:8*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[8*P_BIT_WIDTH-2:7*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[7*P_BIT_WIDTH-2:6*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[6*P_BIT_WIDTH-2:5*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[5*P_BIT_WIDTH-2:4*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[4*P_BIT_WIDTH-2:3*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[3*P_BIT_WIDTH-2:2*P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[2*P_BIT_WIDTH-2:P_BIT_WIDTH] == 6'b111111)
          parallel_correct = 0;
       if(data_in[P_BIT_WIDTH-2:0] == 6'b111111)
          parallel_correct = 0;
    end
    
    
//shift valid for each output
    always_comb begin
       shift_serial = 0;
       shift_parallel = 0;
       valid_serial = 0;
       valid_parallel = 0;
       if(q_interrupt)begin
          if((q_fifo_count < 'b111111) && (q_fifo_count > 0))begin
             shift_serial = 1;
             if(serial_correct)
                valid_serial = 1;
          end else if(q_fifo_count >= 'b111111)begin
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
    assign data_serial = seven_bit_switch(data_in[9*P_BIT_WIDTH-1:8*P_BIT_WIDTH]);
    assign data_parallel[9*P_BIT_WIDTH-1:8*P_BIT_WIDTH] = seven_bit_switch(data_in[9*P_BIT_WIDTH-1:8*P_BIT_WIDTH]);
    assign data_parallel[8*P_BIT_WIDTH-1:7*P_BIT_WIDTH] = seven_bit_switch(data_in[8*P_BIT_WIDTH-1:7*P_BIT_WIDTH]);
    assign data_parallel[7*P_BIT_WIDTH-1:6*P_BIT_WIDTH] = seven_bit_switch(data_in[7*P_BIT_WIDTH-1:6*P_BIT_WIDTH]);
    assign data_parallel[6*P_BIT_WIDTH-1:5*P_BIT_WIDTH] = seven_bit_switch(data_in[6*P_BIT_WIDTH-1:5*P_BIT_WIDTH]);
    assign data_parallel[5*P_BIT_WIDTH-1:4*P_BIT_WIDTH] = seven_bit_switch(data_in[5*P_BIT_WIDTH-1:4*P_BIT_WIDTH]);
    assign data_parallel[4*P_BIT_WIDTH-1:3*P_BIT_WIDTH] = seven_bit_switch(data_in[4*P_BIT_WIDTH-1:3*P_BIT_WIDTH]);
    assign data_parallel[3*P_BIT_WIDTH-1:2*P_BIT_WIDTH] = seven_bit_switch(data_in[3*P_BIT_WIDTH-1:2*P_BIT_WIDTH]);
    assign data_parallel[2*P_BIT_WIDTH-1:  P_BIT_WIDTH] = seven_bit_switch(data_in[2*P_BIT_WIDTH-1:  P_BIT_WIDTH]);
    assign data_parallel[  P_BIT_WIDTH-1:            0] = seven_bit_switch(data_in[  P_BIT_WIDTH-1:            0]);
    

    
endmodule

