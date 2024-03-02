--------------------------------------------------------------
-- Single port Block RAM
--------------------------------------------------------------
-- This file is the port of a part of upstream/rtl/bram.vhd

library	IEEE;
use		IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;

ENTITY spram IS
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := " "
	);
	PORT
	(
		clock   : in  STD_LOGIC;
		address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable  : in  STD_LOGIC := '1';
		wren    : in  STD_LOGIC := '0';
		byteena : in  STD_LOGIC_VECTOR ((data_width/8)-1 DOWNTO 0) := (others => '1');
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END spram;

ARCHITECTURE SYN OF spram IS

	COMPONENT spram_sz IS
		generic (
			addr_width    : integer := 8;
			data_width    : integer := 8;
			numwords      : integer := 2**8;		
			mem_init_file : string := " "
		);
		PORT
		(
			clock   : in  STD_LOGIC;
			address : in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
			data    : in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
			enable  : in  STD_LOGIC := '1';
			wren    : in  STD_LOGIC := '0';
			byteena : in  STD_LOGIC_VECTOR ((data_width/8)-1 DOWNTO 0) := (others => '1');
			q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
			cs      : in  std_logic := '1'
		);
	END COMPONENT;

BEGIN
	spram_sz_inst : component spram_sz
	generic map(addr_width, data_width, 2**addr_width, mem_init_file)
	port map(clock,address,data,enable,wren,byteena,q,cs);
END SYN;