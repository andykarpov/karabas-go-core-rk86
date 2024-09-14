----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    20:30:28 09/09/2024 
-- Design Name: 
-- Module Name:    memory - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity memory is
port (
	CLK50				: in std_logic;
	RESET				: in std_logic;
	
	MA 				: out std_logic_vector(20 downto 0); 	-- sram address
	LOADER_RAM_A	: in std_logic_vector (20 downto 0); 	-- loader address
	VA					: in std_logic_vector (15 downto 0); 	-- video address
	
	MD 				: inout std_logic_vector (15 downto 0) := "ZZZZZZZZZZZZZZZZ";
	N_MRD 			: buffer std_logic_vector(1 downto 0);
	N_MWR 			: buffer std_logic_vector(1 downto 0);
	
	LOADER_ACT 		: in std_logic := '0';
	LOADER_RAM_DO	: in std_logic_vector(7 downto 0);
	LOADER_RAM_WR	: in std_logic := '0';
	
	VID_MEM_O		: out std_logic_vector(7 downto 0);
	VID_RD 			: in std_logic;

	A           	: in std_logic_vector(15 downto 0); 	-- address bus cpu
	DI					: in std_logic_vector(7 downto 0);		-- from cpu
	DO					: out std_logic_vector(7 downto 0);		-- to cpu
	WR_N 				: in std_logic;
	RD 				: in std_logic;
	CE					: in std_logic;								-- cpu clock active 1
	ROM_ACTIVE		: in std_logic
);
end memory;

architecture RTL of memory is
	signal sram_a_r		: std_logic_vector(20 downto 0);
	signal sram_data_o_r	: std_logic_vector(7 downto 0);
	signal sram_data_i_r	: std_logic_vector(7 downto 0);
	signal sram_wr_n 		: std_logic := '1';
	signal sram_rd_n 		: std_logic := '1';	
	signal vid_mem_o_r		: std_logic_vector(7 downto 0);
	signal cpu_mem_o_r		: std_logic_vector(7 downto 0);
begin
	N_MRD(1) <= '1';				--disable second sram ic
	N_MWR(1)	<= '1';				--disable second sram ic

	MA <= sram_a_r;
	N_MRD(0) <= sram_rd_n;		
	N_MWR(0) <= sram_wr_n;		
	
	MD(7 downto 0) <= sram_data_o_r when sram_wr_n = '0' else "ZZZZZZZZ";
	sram_data_i_r <= MD(7 downto 0);
	
	VID_MEM_O <= vid_mem_o_r;
	
	process (CLK50)
	begin 
		if reset = '1' then
			sram_rd_n <= '1';
			sram_wr_n <= '1';
			
			sram_data_o_r <= (others => '0');
			vid_mem_o_r   <= (others => '0');
		elsif rising_edge(CLK50) then 
			if LOADER_ACT = '1' then						-- loader write to sram
				sram_rd_n <= '1';
				sram_wr_n <= LOADER_RAM_WR;
				sram_a_r  <= LOADER_RAM_A;
				sram_data_o_r <= LOADER_RAM_DO;
			elsif VID_RD = '1' then							-- char read
				sram_rd_n <= '0';
				sram_wr_n <= '1';
				sram_a_r  <= "000000" & VA(14 downto 0);
				vid_mem_o_r <= sram_data_i_r;
			elsif WR_N = '0' and A(15) = '0' and ROM_ACTIVE = '0' then  	-- cpu write to sram
				sram_rd_n <= '1';
				sram_wr_n <= WR_N or A(15);
				sram_a_r  <= "000000" & A(14 downto 0);
				sram_data_o_r <= DI;
			elsif RD = '1' and A(15) = '0' 
			

			
			
			
			end if;
		end if;
	end process;
end RTL;

