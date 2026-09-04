`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*; 

module input_flow_ctrl(
    input  logic clk,
    input  logic rst,
    input  logic [w-1:0]value,
    input  logic response,
    output logic [w-1:0]dd_value,
    output logic dd_response,
    output logic resp_sense
    );
    
logic [w-1:0]d_value;
logic d_response;
    
regn #(
    .WIDTH(w + 1)
) delay0(
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({value,  response  }),
    .data_o ({d_value,d_response})
);

regn #(
    .WIDTH(w + 1)
) delay1(
    .clk    (clk),
    .rst    (rst),
    .en     (1'b1),
    .data_i ({d_value, d_response }),
    .data_o ({dd_value,dd_response})
);

assign resp_sense = (response)&(~d_response)&(~dd_response);

endmodule