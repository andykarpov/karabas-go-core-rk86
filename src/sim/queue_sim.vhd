-- Simulation-only model of ipcore_dir/queue (Coregen FIFO, standard read mode: dout is
-- registered on rd_en, like the tsconf fifo.v). Synthesis uses the core netlist.

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity queue is
	port (
		clk        : in  std_logic;
		din        : in  std_logic_vector(23 downto 0);
		wr_en      : in  std_logic;
		rd_en      : in  std_logic;
		dout       : out std_logic_vector(23 downto 0);
		full       : out std_logic;
		empty      : out std_logic;
		data_count : out std_logic_vector(8 downto 0)
	);
end queue;

architecture sim of queue is
	constant DEPTH : integer := 512;
	type mem_t is array (0 to DEPTH-1) of std_logic_vector(23 downto 0);
	signal mem : mem_t;
	signal rptr, wptr : unsigned(8 downto 0) := (others => '0');
	signal count : unsigned(9 downto 0) := (others => '0');
begin
	empty <= '1' when count = 0 else '0';
	full <= '1' when count = DEPTH else '0';
	data_count <= std_logic_vector(count(8 downto 0));

	process (clk)
		variable c : unsigned(9 downto 0);
	begin
		if rising_edge(clk) then
			c := count;
			if wr_en = '1' and count < DEPTH then
				mem(to_integer(wptr)) <= din;
				wptr <= wptr + 1;
				c := c + 1;
			end if;
			if rd_en = '1' and count > 0 then
				dout <= mem(to_integer(rptr));
				rptr <= rptr + 1;
				c := c - 1;
			end if;
			count <= c;
		end if;
	end process;
end sim;
