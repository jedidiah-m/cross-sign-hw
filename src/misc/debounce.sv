`timescale 1ns / 1ps

module debounce(
    input  logic clk,
    input  logic btn,
    output logic btn_out
    );
    
    debouncer dbn(
       .clk      (clk),   
       .btn      (btn),
       .btn_out  (btn_out)
    );
endmodule
