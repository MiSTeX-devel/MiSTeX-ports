--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports
--------------------------------------------------------------
-- This file is the port of a part of upstream/rtl/bram.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dpram_difclk is
	generic (
		addr_width_a  : integer := 8;
		data_width_a  : integer := 8;
	-- in this core this entity is used with the same parameters for _a and _b
	-- so the _b parameters are just dummies
		addr_width_b  : integer := 8; 
		data_width_b  : integer := 8
	); 
	PORT
	(
		address_a	: IN STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0) := (others => '0');
		clock0		: IN STD_LOGIC ;
		clock1		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
		data_b		: IN STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
		enable_a    : IN STD_LOGIC  := '1';
		enable_b    : IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a			: OUT STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
		q_b			: OUT STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';
		cs_b        : in  std_logic := '1'
	);
END dpram_difclk;

architecture syn_difclk of dpram_difclk is
    constant DEPTH        :  positive := 2**addr_width_a;
	subtype  word_t	      is std_logic_vector(data_width_a - 1 downto 0);
	type	 ram_t		  is array(0 to DEPTH - 1) of word_t;
    signal   ram          :  ram_t;

	signal q0 : std_logic_vector((data_width_a - 1) downto 0);
	signal q1 : std_logic_vector((data_width_a - 1) downto 0);
	signal write_enable_a : std_logic;
	signal write_enable_b : std_logic;

begin
	q_a <= q0 when cs_a = '1' else (others => '1');
	q_b <= q1 when cs_b = '1' else (others => '1');

    write_enable_a <= wren_a and cs_a;
    write_enable_b <= wren_b and cs_b;

	process (clock0, clock1)
	begin
		if rising_edge(clock0) then
			if enable_a = '1' then
				if write_enable_a = '1' then
					ram(to_integer(unsigned(address_a))) <= data_a;
					q0 <= data_a;
				else
					q0 <= ram(to_integer(unsigned(address_a)));
				end if;
			end if;
		end if;
		if rising_edge(clock1) then
			if enable_b = '1' then
				if write_enable_a = '1' then
					ram(to_integer(unsigned(address_b))) <= data_b;
					q1 <= data_b;
				else
					q1 <= ram(to_integer(unsigned(address_b)));
				end if;
			end if;
		end if;
	end process;
end architecture;