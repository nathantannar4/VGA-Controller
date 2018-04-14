library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity gray is
	port
	(i: in unsigned(3 downto 0);
	output: out std_logic_vector(2 downto 0));
end gray;

architecture implementation of gray is
--signals here
begin
--logic here
with i select
        output <=  "000" when "0000", --1000000
                                "001" when "0001",--1111001
                                "011" when "0010",--0100100
                                "010" when "0011",--0110000
                                "110" when "0100",--0011001
                                "111" when "0101",--0010010
                                "101" when "0110",--0000010
                                "100" when "0111",--0000000
                                "---" when others;
end architecture;