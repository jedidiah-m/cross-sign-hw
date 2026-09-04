`timescale 1ns / 1ps

module delayed_pulse_gen#(
    parameter int DELAY = 30
)(
    input  logic clk,
    input  logic rst,
    input  logic start_op,
    output logic finish_op
    );
    
logic [7:0] q_count,d_count;

always_ff @(posedge clk)begin
   if(rst)
      q_count <= 0;
   else 
      q_count <= d_count;
   end
   
always_comb begin
   d_count = q_count;
   finish_op = 0;
   if(start_op||(q_count > 0))begin
      d_count = q_count + 1;
      if(q_count == DELAY)begin
         d_count = 0;
         finish_op = 1;
      end
   end
end
    
endmodule