library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debouncer is
    Port (
          clk : in std_logic; 
          btn : in std_logic; 
          btn_out : out std_logic  
    );
end debouncer;

architecture Behavioral of debouncer is
   constant DELAY : integer := 650000; -- Adjust for debounce time (e.g., 6.5ms)
   signal count : integer := 0;
   signal btn_tmp : std_logic := '0';
begin
   process(clk)
      begin
         if rising_edge(clk) then
            if btn /= btn_tmp then
               btn_tmp <= btn;
               count <= 0;
            elsif count = DELAY then
               btn_out <= btn_tmp;
            else
               count <= count + 1;
            end if;
         end if;
   end process;
end Behavioral;