--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

--------------------------------------------------------------------------------

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

entity sprite_buff is
	port (
		I_CLK_12M		: in  std_logic;
		I_CLK_6M_EN		: in  std_logic;
		I_1V				: in  std_logic;
		I_256H			: in  std_logic;
		I_FLIP			: in  std_logic;
		I_CTRL_CLEAR	: in  std_logic;
		I_CTRL_LOAD		: in  std_logic;
		I_CTR				: in  std_logic_vector (7 downto 0);
		I_BUS				: in  std_logic_vector (7 downto 0);
		O_BUS				: out std_logic_vector (7 downto 0)
	);
end sprite_buff;

architecture RTL of sprite_buff is
-- Page 5

	signal clk_6M_n			: std_logic := '0';
	signal s_4X_cs				: std_logic := '0';
	signal s_4X_cs_n			: std_logic := '0';
	signal s_3X_oc_n			: std_logic := '0';
	signal s_3X_sel			: std_logic := '0';
	signal s_6x_clr			: std_logic := '0';
	signal s_inv				: std_logic := '0';
	signal s_m					: std_logic_vector( 7 downto 0) := (others => '1');
	signal s_4X_addr			: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_6X_count			: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_4X_di				: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_4X_do				: std_logic_vector( 7 downto 0) := (others => '0');

	signal zeros_10_to_8	    : std_logic_vector(10 downto 8) := (others => '0');

begin
	O_BUS <= s_m;

	-- some chips require 6MHz while others require /6MHz
	clk_6M_n	<= not I_CLK_6M_EN;

	-- chip 7B6 also 7B8 page 5
	s_3X_oc_n <= I_1V or I_CLK_6M_EN;

	-- chip 1C6 also 1C8 page 5
	s_3X_sel <= not (s_m(0) or s_m(1) or s_m(2));

	-- chip 7B3 also 7B11 page 5
	s_6X_clr  <= (not I_256H) or I_CTRL_CLEAR;

	-- chip 7A3 also 7A6 page 5
	s_inv  <= I_FLIP and I_1V;

	-- chips 5C, 5D also 5A, 5B page 5
	s_4X_addr <= s_6X_count xor (s_inv & s_inv & s_inv & s_inv & s_inv & s_inv & s_inv & s_inv);

	-- chip 7A11 also 7A8 page 5
	s_4X_cs_n <= I_1V and I_256H;
	s_4X_cs   <= not s_4X_cs_n;

	-- chips 3C, 3D also 3A, 3B page 5
	s_4X_di <=																			-- save data to RAM
		(not s_m)	when (s_3X_oc_n = '0') and (s_3X_sel  = '0') else	-- mux enabled, s_m selected
		(not I_BUS)	when (s_3X_oc_n = '0') and (s_3X_sel  = '1') else	-- mux enabled, I_BUS selected
		(others => '1');																-- pullups

	-- chips 6C, 6D also 6A, 6B page 5
	U_6X : process
	begin
		wait until rising_edge(I_CLK_6M_EN);
--		if I_CLK_6M_EN = '0' then
			if    (s_6X_clr = '0') and (I_CTRL_LOAD = '1' ) then		-- clear
				s_6X_count <= (others => '0');
			elsif (s_6X_clr = '1') and (I_CTRL_LOAD = '0' ) then		-- load
				s_6X_count <= I_CTR;
			elsif (s_6X_clr = '1') and (I_CTRL_LOAD = '1' ) then		-- count
				s_6X_count <= s_6X_count + 1;
--			end if;
		end if;
	end process;

	-- chip 4C, 4D also 4A, 4B page 5
	RAM4X : entity work.ram4x
	port map (
		address(10 downto 8) 	=> zeros_10_to_8,
		address( 7 downto 0) 	=> s_4X_addr,
		clock			=> I_CLK_12M,
		clken			=> s_4X_cs,
		data			=> s_4X_di,
		wren			=> clk_6M_n,			-- inverted because unlike the real SRAM, our WE is active high
		q			=> s_4X_do
	);

	-- chips 2C, 2D also 2A, 2B page 5
	U2X : process
	begin
		wait until falling_edge(I_CLK_6M_EN);
--		if I_CLK_6M_EN = '1' then
			if (s_4X_cs_n = '0') then
				s_m <= (not s_4X_do);			-- get data from RAM
			else
				s_m <= (others => '0');			-- pullups (but inverted)
			end if;
--		end if;
	end process;
end RTL;
