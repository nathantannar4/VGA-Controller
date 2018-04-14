library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity vga_demo is
  port(
    CLOCK_50            : in  std_logic;
    KEY                 : in  std_logic_vector(3 downto 0);
    SW                  : in  std_logic_vector(17 downto 0);
    VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);
    VGA_HS              : out std_logic;
    VGA_VS              : out std_logic;
    VGA_BLANK           : out std_logic;
    VGA_SYNC            : out std_logic;
    VGA_CLK             : out std_logic
    );
end vga_demo;

architecture rtl of vga_demo is
  component vga_adapter  ---- Component from the Verilog file: vga_adapter.v
    generic(
      RESOLUTION : string
      );
    port (
      resetn                                       : in  std_logic;
      clock                                        : in  std_logic;
      colour                                       : in  std_logic_vector(2 downto 0);
      x                                            : in  std_logic_vector(7 downto 0);
      y                                            : in  std_logic_vector(6 downto 0);
      plot                                         : in  std_logic;
      VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
      VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic
      );
  end component;

  signal resetn : std_logic;
  signal x      : std_logic_vector(7 downto 0);
  signal y      : std_logic_vector(6 downto 0);
  signal colour : std_logic_vector(2 downto 0);
  signal plot   : std_logic;
begin
  resetn <= KEY(3);
  x      <= SW(7 downto 0);
  y      <= SW(14 downto 8);
  colour <= SW(17 downto 15);
  plot   <= not KEY(0);
  vga_u0 : vga_adapter
    generic map(
      RESOLUTION => "160x120"
      )  ---- Sets the resolution of display (as per vga_adapter.v description)
    port map(
      resetn    => resetn,
      clock     => CLOCK_50,
      colour    => colour,
      x         => x,
      y         => y,
      plot      => plot,
      VGA_R     => VGA_R,
      VGA_G     => VGA_G,
      VGA_B     => VGA_B,
      VGA_HS    => VGA_HS,
      VGA_VS    => VGA_VS,
      VGA_BLANK => VGA_BLANK,
      VGA_SYNC  => VGA_SYNC,
      VGA_CLK   => VGA_CLK
      );



end rtl;
