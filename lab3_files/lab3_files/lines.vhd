library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity line_draw is
  port(CLOCK            	: in  std_logic;
		 RESET					: in  std_logic;
       x0, y0	          	: in  signed(8 downto 0);
       x1, y1          		: in  signed(8 downto 0);
		 START					: in  std_logic;
		 x_plot					: out std_logic_vector(7 downto 0);
		 y_plot					: out std_logic_vector(6 downto 0);
       DONE, PLOT          : out std_logic);
end line_draw;

architecture logic of line_draw is

	signal x1x0, y1y0, dx, dy : signed(8 downto 0); 
	signal moving_down, moving_right, e2_lt_dx, e2_gt_dy : std_logic; 
	signal in_loop, break : std_logic;
	signal err, err_dy, err_dydx, e2, err_next : signed(9 downto 0); 
	signal x, y, x_next, y_next, x_adjusted, y_adjusted, sx, sy : signed(8 downto 0);
	type states is (ready, plotting, finished); 
	signal state : states;
	
begin

	-- datapath for dx, dy, moving_right, moving_down
	x1x0 <= x1 - x0; 
	y1y0 <= y1 - y0;
	moving_right <= not x1x0(8); 
	moving_down <= not y1y0(8);
	-- Multiply dy by -1 when x1 < x0; abs(x1 - x0)
	dx <= x1x0 when moving_right = '1' else -x1x0;
	-- Multiply dy by -1 when y1 > y0; -1 * abs(y1 - y0)
	dy <= -y1y0 when moving_down = '1' else y1y0;
	
	-- Error Datapath
	err_dy <= err + dy when e2_gt_dy = '1' else err;
	err_dydx <= err_dy + dx when e2_lt_dx = '1' else err_dy;
	-- Initial error is dx + dy
	err_next <= err_dydx when in_loop = '1' else ("0" & dx) + ("0" & dy);
	
	-- e2 = 2 * err; ie. shift bits left
	e2 <= err(8 downto 0) & "0";
	-- e2 greater than dy
	e2_gt_dy <= '1' when e2 > dy else '0'; 
	-- e2 less than dx
	e2_lt_dx <= '1' when e2 < dx else '0';
	
	-- X Datapath
	sx <= to_signed(1, sx'length) when moving_right = '1' else to_signed(-1, sx'length);
	x_adjusted <= (x + sx) when e2_gt_dy = '1' else x;
	-- Use local x adjusted for error while in loop, otherwise get x0 from input
	x_next <= x_adjusted when in_loop = '1' else x0; 
	
	-- Y Datapath
	sy <= to_signed(1, sy'length) when moving_down = '1' else to_signed(-1, sy'length);
	y_adjusted <= (y + sy) when e2_lt_dx = '1' else y;
	-- Use local y adjusted for error while in loop, otherwise get y0 from input
	y_next <= y_adjusted when in_loop = '1' else y0; 
	
	-- Flags
	break <= '1' when x = x1 and y = y1 else '0';
	in_loop <= '1' when state = plotting else '0';			  
	
	-- Output
	x_plot <= std_logic_vector(x(7 downto 0));
	y_plot <= std_logic_vector(y(6 downto 0));
	DONE <= '1' when state = finished else '0';
	--DONE <= '0' when state = plotting else '1'; 
	PLOT <= in_loop;
	
	-- State Machine
	process (CLOCK) 
	begin 
	
		if RESET = '0' then 
		
			state <= ready;
			
		elsif rising_edge(CLOCK) then 
		
			-- Clock Flip-Flops
			err <= err_next; 
			x <= x_next; 
			y <= y_next; 
		
			case state is 
			
				when ready => 
				
					if START = '1' then 
						state <= plotting; 
					end if; 
					
				when plotting => 
				
					if break = '1' then 
						state <= finished;
					end if; 
					
				when finished => 
				
					if START = '1' then 
						state <= plotting; 
--					else 
--						state <= ready; 
					end if; 
					
			end case; 
		end if; 
	end process;

end logic; 