`timescale 1ns / 1ps

import keccak_pkg::*;
import rsdp_pkg::*;

module signature_to_serial_out(
    input  logic clk_125mhz_p,
    input  logic clk_125mhz_n,
    input  logic rst_in,
    input  logic gen,
    input  logic read,
    output logic tx
    );
    
logic [w-1:0] data_in,valid_signature_out;

IBUFDS u3 (
      .I (clk_125mhz_p),
      .IB (clk_125mhz_n),
      .O (clk_125mhz_in)
);

BUFG u4 (
      .I(clk_125mhz_in),
      .O(clk)
);
    
input_flow_controller  ifc(
   .clk     (clk),
   .rst     (rst),
   .pulse   (gen_out_pulse),
   .occupied(occupied),
   .request (shift_data_in),
   .data_out(data_in)//w
    );
    
signature_generator  sg(
   .clk                (clk),
   .rst                (rst),
   .shift_data_in      (shift_data_in),
   .data_in            (data_in),//w 
   .request_signature  (request_uart),
   .module_response    (),
   .valid_signature_out(valid_signature_out),//w
   .occupied           (occupied),
   .ended              ()  
    );
    
read_uart   uart_out(
   .clk     (clk),
   .rst     (rst),
   .ended   (read_out_pulse),
   .data_mem(valid_signature_out),//w
   .request (request_uart),
   .tx      (tx)
    );
    
debounce button1(
   .clk     (clk),
   .btn     (gen),
   .btn_out (gen_out)
);

debounce button2(
   .clk     (clk),
   .btn     (read),
   .btn_out (read_out)
);

debounce button3(
   .clk     (clk),
   .btn     (rst_in),
   .btn_out (rst)
);

edge_detect btn1(
   .clk     (clk),
   .rst     (rst),
   .btn_out (gen_out),
   .pulse   (gen_out_pulse)
);

edge_detect btn2(
   .clk     (clk),
   .rst     (rst),
   .btn_out (read_out),
   .pulse   (read_out_pulse)
);
    
endmodule