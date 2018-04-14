library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity plotter is
  port(CLOCK            	: in  std_logic;
		 RESET					: in 	std_logic;
		 X                   : in  std_logic_vector(7 downto 0);
		 Y                   : in  std_logic_vector(6 downto 0);
		 COLOUR              : in  std_logic_vector(2 downto 0);
		 ENABLE              : in  std_logic;
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic;
		 DONE						: out std_logic);
end plotter;

architecture design of plotter is


	--Component from the Verilog file: vga_adapter.v
	component vga_adapter
	generic(RESOLUTION : string);
	port (resetn                                     : in  std_logic;
		 clock                                        : in  std_logic;
		 colour                                       : in  std_logic_vector(2 downto 0);
		 x                                            : in  std_logic_vector(7 downto 0);
		 y                                            : in  std_logic_vector(6 downto 0);
		 plot                                         : in  std_logic;
		 VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
		 VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
	end component;
	
	-- State Map
	-- 00 init
	-- 01 plotx
	-- 10 ploty
	-- 00 done
	signal state : std_logic_vector(1 downto 0) := (others => '0');
	signal local_x : std_logic_vector(7 downto 0);
	signal local_y : std_logic_vector(6 downto 0);
	signal local_colour : std_logic_vector(2 downto 0);
	signal plot: std_logic;
	signal isResetting: std_logic;

begin

	vga_u0 : vga_adapter
	generic map(RESOLUTION => "160x120") 
	port map(resetn    => RESET,
		clock     => CLOCK,
		colour    => local_colour,
		x         => local_x,
		y         => local_y,
		plot      => plot,
		VGA_R     => VGA_R,
		VGA_G     => VGA_G,
		VGA_B     => VGA_B,
		VGA_HS    => VGA_HS,
		VGA_VS    => VGA_VS,
		VGA_BLANK => VGA_BLANK,
		VGA_SYNC  => VGA_SYNC,
		VGA_CLK   => VGA_CLK);
		
	
	DONE <= state(0) AND state(1);
	
	process (RESET, CLOCK)
	variable xdone: std_logic := '0';
	variable ydone: std_logic := '0';
	begin
		
		-- State Change
		if (RESET = '0') then
			state <= "00";
			isResetting <= '1';
		elsif (rising_edge(CLOCK) AND isResetting = '1') then
		
			plot <= state(0) XOR state(1);
			local_colour <= "000"; -- black
		
			case state is
				when "00" =>
					-- init
					local_x <= (others => '0');
					local_y <= (others => '0');
					xdone := '0';
					ydone := '0';
				when "01" =>
					-- plot x
					local_x <= local_x + 1;
					
					if (local_x = 159) then
						xdone := '1';
					end if;
					
				when "10" =>
					-- plot y
					local_y <= local_y + 1;
					ydone := '1';
					
					-- Reset the next x
					local_x <= (others => '0');
					
					if (local_y = 119) then
						-- both x and y are done
						xdone := '1';
					end if;
					
				when "11" =>
					-- done
			end case;
			
			-- Determine Next State
			if (xdone = '0' AND ydone = '0') then
				-- init->plotx
				state <= "01";
			elsif (xdone = '1' AND ydone = '0') then
				-- plotx->ploty
				state <= "10";
				xdone := '0';
			elsif (xdone = '0' AND ydone = '1') then
				-- ploty->plotx
				state <= "01";
				ydone := '0';
			elsif (xdone = '1' AND ydone = '1') then
				-- plotx->done
				state <= "11";
				isResetting <= '0';
			end if;
	
		elsif (rising_edge(CLOCK)) then
			
			local_x <= X;
			local_y <= Y;
			local_colour <= COLOUR;
			plot <= ENABLE;
		
		end if;
	end process;
	
end design;