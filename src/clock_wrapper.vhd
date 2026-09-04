library IEEE; 
use IEEE.STD_LOGIC_1164.ALL;

entity clock_wrapper is
   Port (
      clk_out1:out STD_LOGIC; 
      reset   :in  STD_LOGIC;
      locked  :out STD_LOGIC;
      clk_in1 :in  STD_LOGIC
      );
end clock_wrapper;

architecture Behavioral of clock_wrapper is
   component clock_div is
      port(
         clk_out1:out STD_LOGIC; 
         reset   :in  STD_LOGIC;
         locked  :out STD_LOGIC;
         clk_in1 :in  STD_LOGIC
      );
   end component clock_div;
begin

   dut : clock_div
      port map(
         clk_out1 => clk_out1,
         reset    => reset,
         locked   => locked,
         clk_in1  => clk_in1
      );

end Behavioral;
