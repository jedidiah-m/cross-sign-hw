`timescale 1ns / 1ps

module uart_module_tx#(
  parameter int CLK_HZ = 125_000_000,
  parameter int BAUD   = 1_000_000 
) (
  input  logic       clk,
  input  logic       rst,
  input  logic [7:0] byte_data,
  input  logic       start_pulse,
  output logic       tx,
  output logic       finished_pulse
);

localparam int CLOCK_COUNT = CLK_HZ/BAUD;

logic [6:0]q_count,d_count;
logic [3:0]q_bits,d_bits;
typedef enum logic [1:0] {
    IDLE,
    TRANSMIT
  } state_t;
state_t q_state, d_state;

always_ff @(posedge clk)begin
   if(rst)begin
      q_count <= 0; 
      q_bits  <= 0;
      q_state <= IDLE;
   end else begin
      q_count <= d_count;
      q_bits  <= d_bits;
      q_state <= d_state;
   end
end

always_comb begin
   d_count = q_count;
   d_bits  = q_bits;
   d_state = q_state;
   finished_pulse = 0;
   case(q_state)
      IDLE:begin
         if(start_pulse)begin
            d_count = 0;
            d_bits  = 0;
            d_state = TRANSMIT;
         end
      end
      TRANSMIT:begin
         d_count = q_count +1;
         if(q_count == CLOCK_COUNT - 1)begin
            d_count = 0;
            d_bits = q_bits + 1;
            if(q_bits == 9)begin
               finished_pulse = 1;
               d_bits = 0;
               if(!start_pulse)begin
                  d_count = 0;
                  d_bits  = 0;
                  d_state = IDLE;
               end
            end
         end
      end
   endcase
end

always_comb begin
   tx = 1;
   if(!(q_state == IDLE))begin
      if(q_bits == 0)begin
         tx = 0;
      end else if ((q_bits > 0)&&(q_bits <9))begin
         tx = byte_data[q_bits-1];
      end
   end
end

endmodule