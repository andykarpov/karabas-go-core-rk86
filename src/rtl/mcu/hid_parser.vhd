-------------------------------------------------------------------------------
-- MCU HID keyboard / joystick parser / transformer
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity hid_parser is
	generic 
	(
		NUM_KEYS : integer range 1 to 6 := 2; -- number of simultaneously pressed keys to process
		ALLOW_KEYCODE : boolean := true -- allow ps/2 keycode (tsconf standard)
	);
	port
	(
	 CLK			 : in std_logic;
	 RESET 		 : in std_logic;
	 
	 -- incoming usb hid report data
	 KB_STATUS : in std_logic_vector(7 downto 0);
	 KB_DAT0 : in std_logic_vector(7 downto 0);
	 KB_DAT1 : in std_logic_vector(7 downto 0);
	 KB_DAT2 : in std_logic_vector(7 downto 0);
	 KB_DAT3 : in std_logic_vector(7 downto 0);
	 KB_DAT4 : in std_logic_vector(7 downto 0);
	 KB_DAT5 : in std_logic_vector(7 downto 0);

	 -- joy data from mcu
	 JOY_TYPE_L : in std_logic_vector(2 downto 0);
	 JOY_TYPE_R : in std_logic_vector(2 downto 0);
	 JOY_L : in std_logic_vector(12 downto 0);
	 JOY_R : in std_logic_vector(12 downto 0);

	 -- cpu address for spectrum keyboard row address
	 A : in std_logic_vector(7 downto 0);
	 
	 -- keyboard type
	 KB_TYPE : in std_logic; -- 0=profi xt, 1=spectrum
	 
	 -- kempston joy output data
	 JOY_DO : out std_logic_vector(7 downto 0);

	 -- keyboard output data
	 KB_DO : out std_logic_vector(7 downto 0);
	 
	 -- ZX keyboard matrix
	 KB_ZX : out std_logic_vector(40 downto 0);
	 
	 -- tsconf ps/2 scancode to RTC reg F0
	 KEYCODE: out std_logic_vector(7 downto 0);
	 
	 SHIFTS	: out std_logic_vector(2 downto 0)
	);
end hid_parser;

architecture rtl of hid_parser is
						 
	type rkmatrix IS (RK_K_HOME, RK_K_DEL,   RK_K_ESC,   RK_K_F1,     RK_K_F2,    RK_K_F3,    RK_K_F4,      RK_K_F5,
							RK_K_TAB,  RK_K_SCRLL, RK_K_ENTER, RK_K_BACKSP, RK_K_LEFT,  RK_K_UP,    RK_K_RIGHT,   RK_K_DOWN,
							RK_K_0,    RK_K_1,     RK_K_2,     RK_K_3,      RK_K_4,     RK_K_5,     RK_K_6,       RK_K_7,
							RK_K_8,    RK_K_9,     RK_K_EQ,                 RK_K_COMMA, RK_K_MINUS, RK_K_DOT,
							           RK_K_A,     RK_K_B,     RK_K_C,      RK_K_D,     RK_K_E,     RK_K_F,       RK_K_G,
							RK_K_H,    RK_K_I,     RK_K_J,     RK_K_K,      RK_K_L,     RK_K_M,     RK_K_N,       RK_K_O,
							RK_K_P,    RK_K_Q,     RK_K_R,     RK_K_S,      RK_K_T,     RK_K_U,     RK_K_V,       RK_K_W,
							RK_K_X,    RK_K_Y,     RK_K_Z,                                          RK_K_COMMAUP, RK_K_SPACE
							);

	constant SC_CTL_ON : natural := 0;
	constant SC_BTN_UP : natural := 1;
	constant SC_BTN_DOWN: natural := 2;
	constant SC_BTN_LEFT: natural := 3;
   constant	SC_BTN_RIGHT: natural := 4;
	constant SC_BTN_START: natural := 5;
   constant SC_BTN_A : natural := 6;
	constant SC_BTN_B : natural := 7;
	constant SC_BTN_C : natural := 8;
	constant SC_BTN_X : natural := 9;
	constant SC_BTN_Y : natural := 10;
	constant SC_BTN_Z : natural := 11;
	constant SC_BTN_MODE : natural := 12;
						 
	type kb_matrix is array(rkmatrix) of std_logic;						 
	signal kb_data : kb_matrix := (others => '0'); 
	
	signal data : std_logic_vector(47 downto 0);
	
	signal is_macros : std_logic := '0';
	type macros_machine is (MACRO_START, MACRO_CS_ON, MACRO_SS_ON, MACRO_SS_OFF, MACRO_KEY, MACRO_CS_OFF, MACRO_END);
	signal macros_state : macros_machine := MACRO_START;
	signal macro_cnt : std_logic_vector(21 downto 0) := (others => '0');
	

	
begin 

	-- incoming data of pressed keys from usb hid report
	data <= KB_DAT5 & KB_DAT4 & KB_DAT3 & KB_DAT2 & KB_DAT1 & KB_DAT0;
	
	-- usb hid to ps/2 keycode
	G_PS2_LUT: if ALLOW_KEYCODE generate
	U_PS2_LUT: entity work.usb_ps2_lut
	port map(
		kb_status => KB_STATUS,
		kb_data => KB_DAT0,
		keycode => KEYCODE
	);
	end generate G_PS2_LUT;

	process( kb_data, A)
	begin
		KB_DO(0) <=	not(( kb_data(RK_K_HOME)  and not( A(0)  ) ) 
					or    ( kb_data(RK_K_TAB)  and not(   A(1)  ) ) 
					or    ( kb_data(RK_K_0) and not(    A(2) ) ) 
					or    ( kb_data(RK_K_8) and not(    A(3) ) ) 
					--or    ( kb_data() and not(    A(4) ) ) 
					or    ( kb_data(RK_K_H) and not(    A(5) ) ) 
					or    ( kb_data(RK_K_P) and not(  A(6) ) ) 
					or    ( kb_data(RK_K_X) and not(   A(7) ) )  );

		KB_DO(1) <=	not( ( kb_data(RK_K_DEL)  and not(A(0) ) ) 
					or   ( kb_data(RK_K_SCRLL)  and not(A(1) ) ) 
					or   ( kb_data(RK_K_1) and not(A(2)) ) 
					or   ( kb_data(RK_K_9) and not(A(3)) ) 
					or   ( kb_data(RK_K_A) and not(A(4)) ) 
					or   ( kb_data(RK_K_I) and not(A(5)) ) 
					or   ( kb_data(RK_K_Q) and not(A(6)) ) 
					or   ( kb_data(RK_K_Y) and not(A(7)) ) );

		KB_DO(2) <=		not( ( kb_data(RK_K_ESC) and not( A(0)) ) 
					or   ( kb_data(RK_K_ENTER) and not( A(1)) ) 
					or   ( kb_data(RK_K_2) and not(A(2)) ) 
					or   ( kb_data(RK_K_EQ) and not(A(3)) ) 
					or   ( kb_data(RK_K_B) and not(A(4)) ) 
					or   ( kb_data(RK_K_J) and not(A(5)) ) 
					or   ( kb_data(RK_K_R) and not(A(6)) ) 
					or   ( kb_data(RK_K_Z) and not(A(7)) ) );

		KB_DO(3) <=		not( ( kb_data(RK_K_F1) and not( A(0)) ) 
					or   ( kb_data(RK_K_BACKSP) and not( A(1)) ) 
					or   ( kb_data(RK_K_3) and not(A(2)) ) 
					--or   ( kb_data(ZX_K_4) and not(A(3)) ) 
					or   ( kb_data(RK_K_C) and not(A(4)) ) 
					or   ( kb_data(RK_K_K) and not(A(5)) ) 
					or   ( kb_data(RK_K_S) and not(A(6)) )); 
					--or   ( kb_data(ZX_K_N) and not(A(7)) ) );

		KB_DO(4) <=		not( ( kb_data(RK_K_F2) and not( A(0)) ) 
					or   ( kb_data(RK_K_LEFT) and not( A(1)) ) 
					or   ( kb_data(RK_K_4) and not(A(2)) ) 
					or   ( kb_data(RK_K_COMMA) and not(A(3)) ) 
					or   ( kb_data(RK_K_D) and not(A(4)) ) 
					or   ( kb_data(RK_K_L) and not(A(5)) ) 
					or   ( kb_data(RK_K_T) and not(A(6)) ) );
					--or   ( kb_data(ZX_K_B) and not(A(7)) ) );
					
		KB_DO(5) <=		not( ( kb_data(RK_K_F3) and not( A(0)) ) 
					or   ( kb_data(RK_K_UP) and not( A(1)) ) 
					or   ( kb_data(RK_K_5) and not(A(2)) ) 
					or   ( kb_data(RK_K_MINUS) and not(A(3)) ) 
					or   ( kb_data(RK_K_E) and not(A(4)) ) 
					or   ( kb_data(RK_K_M) and not(A(5)) ) 
					or   ( kb_data(RK_K_U) and not(A(6)) ) );
					--or   ( kb_data(ZX_K_B) and not(A(7)) ) );
			
		KB_DO(6) <=		not( ( kb_data(RK_K_F4) and not( A(0)) ) 
					or   ( kb_data(RK_K_RIGHT) and not( A(1)) ) 
					or   ( kb_data(RK_K_6) and not(A(2)) ) 
					or   ( kb_data(RK_K_DOT) and not(A(3)) ) 
					or   ( kb_data(RK_K_F) and not(A(4)) ) 
					or   ( kb_data(RK_K_N) and not(A(5)) ) 
					or   ( kb_data(RK_K_V) and not(A(6)) ) 
					or   ( kb_data(RK_K_COMMAUP) and not(A(7)) ) );
					
		KB_DO(7) <=		not( ( kb_data(RK_K_F5) and not( A(0)) ) 
					or   ( kb_data(RK_K_DOWN) and not( A(1)) ) 
					or   ( kb_data(RK_K_7) and not(A(2)) ) 
					--or   ( kb_data(ZX_K_5) and not(A(3)) ) 
					or   ( kb_data(RK_K_G) and not(A(4)) ) 
					or   ( kb_data(RK_K_O) and not(A(5)) ) 
					or   ( kb_data(RK_K_W) and not(A(6)) ) 
					or   ( kb_data(RK_K_SPACE) and not(A(7)) ) );
		
		SHIFTS(0) <= not (KB_STATUS(1) or KB_STATUS(5)); --pseudografic (LCTRL RCTRL)
		SHIFTS(1) <= not KB_STATUS(0);
		SHIFTS(2) <= not KB_STATUS(4);
		
	end process;

process (RESET, CLK)
	begin
		if RESET = '1' then
			kb_data <= (others => '0');
			
		elsif CLK'event and CLK = '1' then
				
				kb_data <= (others => '0');
				--if KB_STATUS(7) = '1' then end if;

				for II in 0 to NUM_KEYS-1 loop		
				case data((II+1)*8-1 downto II*8) is							
				
					-- Punctuation
					when X"37" =>	kb_data(RK_K_DOT) <= '1';	-- .
					when X"2d" =>	kb_data(RK_K_MINUS) <= '1';	-- -
					when X"35" =>	kb_data(RK_K_COMMAUP) <= '1';	-- `
					when X"36" =>	kb_data(RK_K_COMMA) <= '1';	-- ,
					when X"2e" =>	kb_data(RK_K_EQ) <= '1';	-- =

					-- Cursor 
					when X"50" => kb_data(RK_K_LEFT) <= '1'; 
					when X"52" => kb_data(RK_K_UP) <= '1';
					when X"51" => kb_data(RK_K_DOWN) <= '1'; 
					when X"4f" => kb_data(RK_K_RIGHT) <= '1'; 

					-- ESC 
					when X"29" => kb_data(RK_K_ESC) <= '1';
					
					--DEL
					when X"4c" => kb_data(RK_K_DEL) <= '1';
					-- Backspace 
					when X"2a" => kb_data(RK_K_BACKSP) <= '1';
					
					-- Tab
					when X"2b" => kb_data(RK_K_TAB) <= '1';
					
					-- Scroll lock ()
					when X"47" => kb_data(RK_K_SCRLL) <= '1';
					
					-- Home
					when X"4a" => kb_data(RK_K_HOME) <= '1';
					
					-- Enter
					when X"28" =>	kb_data(RK_K_ENTER) <= '1'; -- normal
					when X"58" =>  kb_data(RK_K_ENTER) <= '1'; -- keypad 					
					
					-- Space 
					when X"2c" =>	kb_data(RK_K_SPACE) <= '1';
					
					-- Letters
					when X"04" =>	kb_data(RK_K_A) <= '1'; -- A
					when X"05" =>	kb_data(RK_K_B) <= '1'; -- B								
					when X"06" =>	kb_data(RK_K_C) <= '1'; -- C
					when X"07" =>	kb_data(RK_K_D) <= '1'; -- D
					when X"08" =>	kb_data(RK_K_E) <= '1'; -- E
					when X"09" =>	kb_data(RK_K_F) <= '1'; -- F
					when X"0a" =>	kb_data(RK_K_G) <= '1'; -- G
					when X"0b" =>	kb_data(RK_K_H) <= '1'; -- H
					when X"0c" =>	kb_data(RK_K_I) <= '1'; -- I
					when X"0d" =>	kb_data(RK_K_J) <= '1'; -- J
					when X"0e" =>	kb_data(RK_K_K) <= '1'; -- K
					when X"0f" =>	kb_data(RK_K_L) <= '1'; -- L
					when X"10" =>	kb_data(RK_K_M) <= '1'; -- M
					when X"11" =>	kb_data(RK_K_N) <= '1'; -- N
					when X"12" =>	kb_data(RK_K_O) <= '1'; -- O
					when X"13" =>	kb_data(RK_K_P) <= '1'; -- P
					when X"14" =>	kb_data(RK_K_Q) <= '1'; -- Q
					when X"15" =>	kb_data(RK_K_R) <= '1'; -- R
					when X"16" =>	kb_data(RK_K_S) <= '1'; -- S
					when X"17" =>	kb_data(RK_K_T) <= '1'; -- T
					when X"18" =>	kb_data(RK_K_U) <= '1'; -- U
					when X"19" =>	kb_data(RK_K_V) <= '1'; -- V
					when X"1a" =>	kb_data(RK_K_W) <= '1'; -- W
					when X"1b" =>	kb_data(RK_K_X) <= '1'; -- X
					when X"1c" =>	kb_data(RK_K_Y) <= '1'; -- Y
					when X"1d" =>	kb_data(RK_K_Z) <= '1'; -- Z
					
					-- Digits
					when X"1e" =>	kb_data(RK_K_1) <= '1'; -- 1
					when X"1f" =>	kb_data(RK_K_2) <= '1'; -- 2
					when X"20" =>	kb_data(RK_K_3) <= '1'; -- 3
					when X"21" =>	kb_data(RK_K_4) <= '1'; -- 4
					when X"22" =>	kb_data(RK_K_5) <= '1'; -- 5
					when X"23" =>	kb_data(RK_K_6) <= '1'; -- 6
					when X"24" =>	kb_data(RK_K_7) <= '1'; -- 7
					when X"25" =>	kb_data(RK_K_8) <= '1'; -- 8
					when X"26" =>	kb_data(RK_K_9) <= '1'; -- 9
					when X"27" =>	kb_data(RK_K_0) <= '1'; -- 0
					
					-- Numpad digits
					when X"59" =>	kb_data(RK_K_1) <= '1'; -- 1
					when X"5A" =>	kb_data(RK_K_2) <= '1'; -- 2
					when X"5B" =>	kb_data(RK_K_3) <= '1'; -- 3
					when X"5C" =>	kb_data(RK_K_4) <= '1'; -- 4
					when X"5D" =>	kb_data(RK_K_5) <= '1'; -- 5
					when X"5E" =>	kb_data(RK_K_6) <= '1'; -- 6
					when X"5F" =>	kb_data(RK_K_7) <= '1'; -- 7
					when X"60" =>	kb_data(RK_K_8) <= '1'; -- 8
					when X"61" =>	kb_data(RK_K_9) <= '1'; -- 9
					when X"62" =>	kb_data(RK_K_0) <= '1'; -- 0
					
					-- Fx keys
					when X"3a" =>  kb_data(RK_K_F1) <= '1'; -- F1
					when X"3b" =>  kb_data(RK_K_F2) <= '1'; -- F2
					when X"3c" =>  kb_data(RK_K_F3) <= '1';	-- F3
					when X"3d" =>  kb_data(RK_K_F4) <= '1';	-- F4
					when X"3e" =>  kb_data(RK_K_F5) <= '1';	-- F5
					
					when others => null;
					
				end case;
				end loop;
							
		end if;
	end process;

end rtl;