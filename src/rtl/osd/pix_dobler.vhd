library IEEE; 
use IEEE.std_logic_1164.all; 
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.all;

entity pix_doubler is
	port (
		CLK	: in std_logic;
		LOAD	: in std_logic;
		D		: in std_logic_vector(7 downto 0);
		QUAD 	: in std_logic := '0';
		SINGL : in std_logic := '0';
		DOUT	: out std_logic
	);
end entity;

architecture rtl of pix_doubler is
	signal shift_8	 : std_logic_vector(7 downto 0);
	signal shift_16 : std_logic_vector(15 downto 0);
	signal shift_32 : std_logic_vector(31 downto 0);
	signal cnt : std_logic_vector(3 downto 0);
begin

	process(CLK, shift_8,shift_16, shift_32)
	begin
		if falling_edge(CLK) then
			if LOAD = '1' then 
				shift_8  <= D;
				
				shift_16 <= D(7) & D(7) & 
								D(6) & D(6) & 
								D(5) & D(5) & 
								D(4) & D(4) & 
								D(3) & D(3) & 
								D(2) & D(2) & 
								D(1) & D(1) & 
								D(0) & D(0);
								
				shift_32 <= D(7) & D(7) & D(7) & D(7) & 
								D(6) & D(6) & D(6) & D(6) & 
								D(5) & D(5) & D(5) & D(5) & 
								D(4) & D(4) & D(4) & D(4) & 
								D(3) & D(3) & D(3) & D(3) & 
								D(2) & D(2) & D(2) & D(2) & 
								D(1) & D(1) & D(1) & D(1) & 
								D(0) & D(0) & D(0) & D(0);
								
				cnt <= "0000";				
			else 
				shift_8  <= shift_8(6 downto 0) & '0';
				shift_16 <= shift_16(14 downto 0) & '0';
				shift_32 <= shift_32(30 downto 0) & '0';
				cnt <= cnt + 1;
			end if;
		end if;
	end process;

process (SINGL, QUAD, shift_8, shift_16, shift_32)
begin
	if SINGL = '1' and QUAD = '0' then
		DOUT <= shift_8(7);
	elsif SINGL = '1' and QUAD = '1' then
		DOUT <= shift_16(15);
	elsif SINGL = '0' and QUAD = '1' then
		DOUT <= shift_32(31);
	else 
		DOUT <= shift_16(15);
	end if;
end process;

end architecture;
