`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module pad_generator #(
    parameter int DEPTH = (2*LAMBDA)/w
)(
    input  logic clk,
    input  logic reset,
    input  logic shift,
    input  logic rotate,
    input  logic [w-1:0] data_in,
    output  logic [w-1:0] data_out
    );
    
logic [63:0] d_data[DEPTH-1:0];
logic [63:0] q_data[DEPTH-1:0];
    
    always_ff @(posedge clk)begin
        if(reset)
            for (int i = 0; i < DEPTH ; i++)
                q_data[i] <= 0;
        else 
                q_data <= d_data;
    end
    
    always_comb begin
        d_data = q_data;
        if((shift) && (!rotate))begin 
           d_data[0] = data_in;
           for (int i = 1; i < DEPTH; i++)begin
              d_data[i] = q_data[i-1];
           end
        end
        if((!shift) && (rotate))begin 
           d_data[0] = q_data[DEPTH-1];
           for (int i = 1; i < DEPTH; i++)begin
              d_data[i] = q_data[i-1];
           end
        end
    end
    
    assign data_out = q_data[DEPTH-1];
    
endmodule
