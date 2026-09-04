`timescale 1ns / 1ps

module edge_detect(
    input  logic clk,
    input  logic rst,
    input  logic btn_out,
    output logic pulse
    );
    
logic q0,d0,q1,d1;   

always_ff @(posedge clk)begin
   if(rst)begin
      q0 <= 0; 
      q1 <= 0;
   end else begin
      q0 <= d0;
      q1 <= d1;
   end
end

assign d0 = btn_out;
assign d1 = d0&(~q0);
assign pulse = q1;
    
endmodule