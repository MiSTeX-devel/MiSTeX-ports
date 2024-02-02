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

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity PROG_ROMS is
	port (
		clk_48M     : in  std_logic;
		dn_addr     : in  std_logic_vector(16 downto 0);
		dn_data     : in  std_logic_vector(7 downto 0);
		dn_wr       : in  std_logic;

		I_CLK       : in  std_logic;
		I_ROM_SEL   : in  std_logic_vector( 4 downto 0);
		I_ADDR      : in  std_logic_vector(12 downto 0);
		--
		O_DATA      : out std_logic_vector( 7 downto 0)
	);
end;

architecture RTL of PROG_ROMS is
	component dpram is
		generic (
			 addr_width_g : integer := 8;
			 data_width_g : integer := 8
		); 
		PORT
		(
			address_a	: IN STD_LOGIC_VECTOR (addr_width_g-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (addr_width_g-1 DOWNTO 0);
			clock_a		: IN STD_LOGIC  := '1';
			clock_b		: IN STD_LOGIC ;
			data_a		: IN STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0);
			data_b		: IN STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0) := (others => '0');
			enable_a    : IN STD_LOGIC  := '1';
			enable_b    : IN STD_LOGIC  := '1';
			wren_a		: IN STD_LOGIC  := '0';
			wren_b		: IN STD_LOGIC  := '0';
			q_a			: OUT STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0);
			q_b			: OUT STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0)
		);
	END component;

	signal ROMD_1J : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1L : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1M : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1N : std_logic_vector( 7 downto 0) := (others => '0');
	signal ROMD_1R : std_logic_vector( 7 downto 0) := (others => '0');
	
	signal 
		ROM_1J_cs,
		ROM_1L_cs,
		ROM_1M_cs,
		ROM_1N_cs,
		ROM_1R_cs : std_logic;

begin

	ROM_1J_cs <= '1' when dn_addr(16 downto 13) = X"8" else '0';
	ROM_1L_cs <= '1' when dn_addr(16 downto 13) = X"9" else '0';
	ROM_1M_cs <= '1' when dn_addr(16 downto 13) = X"A" else '0';
	ROM_1N_cs <= '1' when dn_addr(16 downto 13) = X"B" else '0';
	ROM_1R_cs <= '1' when dn_addr(16 downto 13) = X"C" else '0';

	ROM_1J : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_1J_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK,
		address_b => I_ADDR,
		q_b       => ROMD_1J
	);

	ROM_1L : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_1L_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK,
		address_b => I_ADDR,
		q_b       => ROMD_1L
	);

	ROM_1M : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_1M_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK,
		address_b => I_ADDR,
		q_b       => ROMD_1M
	);

	ROM_1N : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_1N_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK,
		address_b => I_ADDR,
		q_b       => ROMD_1N
	);
	
	ROM_1R : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_1R_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK,
		address_b => I_ADDR,
		q_b       => ROMD_1R
	);

	O_DATA <=
		ROMD_1J when I_ROM_SEL = "11110" else
		ROMD_1L when I_ROM_SEL = "11101" else
		ROMD_1M when I_ROM_SEL = "11011" else
		ROMD_1N when I_ROM_SEL = "10111" else
		ROMD_1R when I_ROM_SEL = "01111" else
		(others => '0');
end RTL;
