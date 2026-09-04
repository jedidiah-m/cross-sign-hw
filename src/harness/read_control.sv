`timescale 1ns / 1ps

module read_control(
    input  logic clk,
    input  logic rst,
    input  logic ended,
    input  logic finished_pulse,
    input  logic [63:0]data_mem,
    output logic request,
    output logic [7:0]byte_data,
    output logic start_pulse
    );
localparam int MAX_ADRESS = SIG_SIZE;
logic [13:0] q_count,d_count;
logic [2:0]  q_bytes,d_bytes;
logic [63:0] q_buff,d_buff;

always_ff @(posedge clk)begin
   if(rst)begin
      q_count <= 0; 
      q_bytes <= 0;
      q_buff  <= 0;
   end else begin
      q_count <= d_count;
      q_bytes <= d_bytes;
      q_buff  <= d_buff;
   end
end
    
always_comb begin
   d_bytes = q_bytes;
   if(finished_pulse)begin
      d_bytes = q_bytes + 1;
   end
end

always_comb begin
   d_count = q_count;
   if(finished_pulse&&(q_bytes == 7))begin
      d_count = q_count + 1;
   end
   if(q_count == MAX_ADRESS)begin
      d_count = 0;
   end
end
    
assign start_pulse = ((finished_pulse&&(!((q_count == MAX_ADRESS-1)&&(q_bytes == 7)))) || ended);
assign request = ((finished_pulse&&(!(q_count == MAX_ADRESS-1))&&(q_bytes == 7)) || ended);

always_comb begin
   d_buff = q_buff;
   if(finished_pulse)begin
      d_buff = {q_buff,8'b0};
      if(request)begin
         d_buff = data_mem;
      end
   end
   if(ended)begin
      d_buff = data_mem;
   end
end

assign byte_data = q_buff[63 -: 8];
    
endmodule