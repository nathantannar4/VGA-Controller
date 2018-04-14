library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity lab3 is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic;
		 LEDR : out std_logic_vector(17 downto 0);
		 LEDG: out std_logic_vector(7 downto 0));
end lab3;

architecture rtl of lab3 is
	 
	component plotter
	port (CLOCK	                                     : in  std_logic;
		 RESET                                        : in  std_logic;
		 X                                            : in  std_logic_vector(7 downto 0);
		 Y                                            : in  std_logic_vector(6 downto 0);
		 COLOUR                                       : in  std_logic_vector(2 downto 0);
		 ENABLE                                       : in  std_logic;
		 VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
		 VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic;
		 DONE												 		 : out std_logic);
	end component;

	component line_draw
	port(CLOCK            	: in  std_logic;
		 RESET					: in  std_logic;
       x0, x1	          	: in  signed(8 downto 0);
       y0, y1          		: in  signed(8 downto 0);
		 START					: in  std_logic;
		 x_plot					: out std_logic_vector(7 downto 0);
		 y_plot					: out std_logic_vector(6 downto 0);
       DONE, PLOT          : out std_logic);
	end component;
	
	component gray
	port(i            		: in  unsigned(3 downto 0);
		  output					: out std_logic_vector(2 downto 0));
	end component;
	
	signal PLOT_LINE, LINE_PLOT_DONE, PLOT_TRIANGLE, ERASE_ENABLED, ERASE, RESET, START, CLOCK, SLOW_CLOCK, ONE_HZ_CLOCK : std_logic;
	signal x : std_logic_vector(7 downto 0);
	signal y : std_logic_vector(6 downto 0);
	signal x0, x1, y0, y1 : signed(8 downto 0);
	signal GRAY_COLOR, COLOR : std_logic_vector(2 downto 0);
	signal ENABLE_PLOT, PLOTTING_DONE  : std_logic;
	signal i : unsigned(3 downto 0) := to_unsigned(1, 4);
	signal i8: signed(8 downto 0);
	signal clock_counter : std_logic_vector(25 downto 0) := (others => '0');
	
	type states is (idle, drawing, waiting, erasing, finished); 
	signal state : states := idle;
	
	type bonus_states is (setting, bottom, height, hypotenuse, complete);
	signal bonus_state : bonus_states := setting;

begin

	-- Port Mapping to other components
	plot_component: plotter
	port map(CLOCK     => CLOCK_50,
				RESET     => RESET,
				X         => x,
				Y         => y,
				COLOUR    => COLOR,
				ENABLE	 => ENABLE_PLOT,
				VGA_R     => VGA_R,
				VGA_G     => VGA_G,
				VGA_B     => VGA_B,
				VGA_HS    => VGA_HS,
				VGA_VS    => VGA_VS,
				VGA_BLANK => VGA_BLANK,
				VGA_SYNC  => VGA_SYNC,
				VGA_CLK   => VGA_CLK,
				DONE 		 => PLOTTING_DONE);
		
	line_component: line_draw
	port map(CLOCK 	=> CLOCK_50,
				RESET		=> RESET,
				x0			=> x0,
				x1			=> x1,
				y0			=> y0,
				y1			=> y1,
				START		=> PLOT_LINE,
				x_plot	=> x,
				y_plot	=> y,
				DONE		=> LINE_PLOT_DONE,
				PLOT		=> ENABLE_PLOT);
	
	gray_component: gray
	port map(i 			=> (i mod 8),
				output	=> GRAY_COLOR);

	-- Key/Switch Mapping
	START <= SW(0);
	ERASE_ENABLED <= SW(1);
	RESET <= KEY(3);
	PLOT_TRIANGLE <= KEY(0);
	
	-- 1Hz for 1 second delay between states  
	ONE_HZ_CLOCK <= clock_counter(25);
	
	-- Few 100 Hz
	SLOW_CLOCK <= clock_counter(20);
	
	-- Task #3/#4 Need different clock cycles
	CLOCK <= ONE_HZ_CLOCK when ERASE_ENABLED = '1' else SLOW_CLOCK;
	
	-- For Debugging
	LEDR(3 downto 0) <= std_logic_vector(i);
	LEDG(7) <= CLOCK;
	LEDR(17) <= ERASE;
	LEDR(15) <= PLOT_LINE;
	LEDR(13) <= LINE_PLOT_DONE;
	with state select
		LEDG(4 downto 0) <= "00001" when idle,
								  "00010" when drawing,
								  "00100" when waiting,
								  "01000" when erasing,
								  "10000" when finished,
								  "-----" when others;
								  
	
	-- Color Datapath
	COLOR <= "000" when ERASE = '1' else GRAY_COLOR;
	
	-- Erase Datapath
	ERASE <= '1' when state = erasing else '0';
	
	-- i * 8; same as i shifted left by 3 bits
	i8 <= "00" & signed(i) & "000"; -- i * 8
	
	-- Coordinate Datapaths for Task #3/#4
--	x0 <= to_signed(0, 9);
--	x1 <= to_signed(159, 9);
--	y0 <= i8;
--	y1 <= to_signed(120, y1'length) - i8;
	
	TRIANGLE_SKETCHER: process (SLOW_CLOCK, PLOT_TRIANGLE)
	begin
	
		if rising_edge(SLOW_CLOCK) then
			
			case bonus_state is

				when setting =>
				
					if PLOT_TRIANGLE = '0' then
						bonus_state <= bottom;
						
						-- Prep Next State
						PLOT_LINE <= '1';
						x0 <= signed("0" & SW(17 downto 10));
						x1 <= to_signed(159, 9) - signed("0" & SW(9 downto 2));
						y0 <= to_signed(100, 9);
						y1 <= to_signed(100, 9);
					end if;
				
		
				when bottom =>
				
					PLOT_LINE <= '0';
					
					if LINE_PLOT_DONE = '1' then
						bonus_state <= height;
						
						-- Prep Next State
						PLOT_LINE <= '1';
						x0 <= signed("0" & SW(17 downto 10));
						x1 <= signed("0" & SW(17 downto 10));
						y0 <= to_signed(20, 9);
						y1 <= to_signed(100, 9);
					end if;
				
				when height =>
					
					PLOT_LINE <= '0';
					
					if LINE_PLOT_DONE = '1' then
						bonus_state <= hypotenuse;
						
						-- Prep Next State
						PLOT_LINE <= '1';
						x0 <= signed("0" & SW(17 downto 10));
						x1 <= to_signed(159, 9) - signed("0" & SW(9 downto 2));
						y0 <= to_signed(20, 9);
						y1 <= to_signed(100, 9);
					end if;
				
				when hypotenuse =>
				
					PLOT_LINE <= '0';
					
					if LINE_PLOT_DONE = '1' then
						bonus_state <= complete;
					end if;
				
				when complete =>
				
					-- Done
					bonus_state <= setting;
				
			end case;
	
		end if;
	end process;
	
--	STATE_MACHINE: process (CLOCK, RESET)
--	begin
--	
--		if RESET = '0' then
--		
--			i <= to_unsigned(1,4);
--			state <= idle;
--			
--		elsif rising_edge(CLOCK) then
--			
--			case state is
--			
--				when idle =>
--				
--					if START = '1' then
--						state <= drawing;
--					end if;
--		
--				when drawing =>
--					
--					state <= waiting;
--					-- Activate Line Plotting for color draw
--					PLOT_LINE <= '1';
--				
--				when waiting =>
--					
--					-- Dectivate Line Plotting for color draw
--					PLOT_LINE <= '0';
--					
--					if LINE_PLOT_DONE = '1' then
--						
--						-- For Task #3 Erasing is required
--						if ERASE_ENABLED = '1' then
--						
--							state <= erasing;
--							-- Activate Line Plotting for black color (erase) draw
--							PLOT_LINE <= '1';
--						
--						-- For Task #3 Erasing is not required
--						else
--						
--							if i = to_unsigned(14, 4) then
--								state <= finished;
--							else
--								i <= i + 1;
--								state <= drawing;
--							end if;
--						
--						end if;
--						
--					end if;
--				
--				when erasing =>
--					
--					-- Dectivate Line Plotting for color draw
--					PLOT_LINE <= '0';
--					
--					if LINE_PLOT_DONE = '1' then
--					
--						if i = to_unsigned(14, 4) then
--							state <= finished;
--						else
--							i <= i + 1;
--							state <= drawing;
--						end if;
--						
--					end if;
--				
--				when finished =>
--				
--					-- Finished Looping 14 Lines
--					if START = '1' then
--						i <= to_unsigned(1, 4);
--						state <= drawing;
--					else
--						state <= idle;
--					end if;
--					
--					
--			end case;
--			
--		end if;
--	end process;
	
	-- A process to scale the 50MHz clock to a 1Hz clock by counting up to 50M
	PRESCALER: process (CLOCK_50)
	begin
		if rising_edge(CLOCK_50) then
			clock_counter <= clock_counter + 1;
			if clock_counter > "10111110101111000010000000" then
				clock_counter <= (others => '0');
			end if;
		end if;
	end process;
	
end RTL;


