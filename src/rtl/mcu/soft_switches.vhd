-------------------------------------------------------------------------------
-- MCU Soft switches receiver
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity soft_switches is
	port(
	CLK : in std_logic;	
	SOFTSW_COMMAND : in std_logic_vector(15 downto 0);
	
	ROM_BANK : out std_logic_vector(1 downto 0);
	TURBO_FDC : out std_logic;
	COVOX : out std_logic;
	PSG_MIX : out std_logic_vector(1 downto 0);
	PSG_TYPE : out std_logic;
	VIDEO : out std_logic;
	VSYNC : out std_logic;
	TURBO : out std_logic_vector(2 downto 0);
	SWAP_FDD : out std_logic;
	JOY_TYPE_L : out std_logic_vector(2 downto 0);
	JOY_TYPE_R : out std_logic_vector(2 downto 0);
	MODE : out std_logic_vector(1 downto 0);
	DIVMMC_EN : out std_logic;
	NEMOIDE_EN : out std_logic;
	KB_TYPE : out std_logic;
	PAUSE : out std_logic;
	NMI : out std_logic;
	RESET : out std_logic;
	GS_RESET : out std_logic;
	VMODE:out std_logic;
	SOUND:out std_logic;
	SPEED : 	out std_logic;
	SND : out std_logic;
	BIP : 	out std_logic;
	ROM_SEL : out std_logic_vector(1 downto 0);
	AUTORUN : 	out std_logic
	);
end soft_switches;

architecture rtl of soft_switches is
	signal prev_command : std_logic_vector(15 downto 0) := x"FFFF";
begin 

process (CLK, prev_command, SOFTSW_COMMAND)
begin
	if rising_edge(CLK) then 
		if (prev_command /= SOFTSW_COMMAND) then
			prev_command <= SOFTSW_COMMAND;
			case SOFTSW_COMMAND(15 downto 8) is
				when x"00" => VMODE <= SOFTSW_COMMAND(0);
				when x"01" => SOUND <= SOFTSW_COMMAND(0);
				when x"02" => ROM_SEL <= SOFTSW_COMMAND(1 downto 0);
				when x"03" => AUTORUN <= SOFTSW_COMMAND(0);
				when x"04" => RESET <= SOFTSW_COMMAND(0);
				when others => null;
			end case;
		end if;
	end if;
end process;

end rtl;