--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity dpram is
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := "none"
	);
	PORT
	(
		clock		: in  STD_LOGIC;

		address_a	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0);
		data_a		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_a		: in  STD_LOGIC := '1';
		wren_a		: in  STD_LOGIC := '0';
		q_a			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_a        : in  std_logic := '1';

		address_b	: in  STD_LOGIC_VECTOR (addr_width-1 DOWNTO 0) := (others => '0');
		data_b		: in  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0) := (others => '0');
		enable_b	: in  STD_LOGIC := '1';
		wren_b		: in  STD_LOGIC := '0';
		q_b			: out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs_b        : in  std_logic := '1'
	);
end entity;


ARCHITECTURE SYN OF dpram IS
	component dpram_dif is
		generic (
			addr_width_a  : integer := 8;
			data_width_a  : integer := 8;
			addr_width_b  : integer := 8;
			data_width_b  : integer := 8;
			mem_init_file : string := "none"
		);
		PORT
		(
			clock			: in  STD_LOGIC;
			
			address_a	: in  STD_LOGIC_VECTOR (addr_width_a-1 DOWNTO 0);
			data_a		: in  STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0) := (others => '0');
			enable_a		: in  STD_LOGIC := '1';
			wren_a		: in  STD_LOGIC := '0';
			q_a			: out STD_LOGIC_VECTOR (data_width_a-1 DOWNTO 0);
			cs_a        : in  std_logic := '1';
	
			address_b	: in  STD_LOGIC_VECTOR (addr_width_b-1 DOWNTO 0) := (others => '0');
			data_b		: in  STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0) := (others => '0');
			enable_b		: in  STD_LOGIC := '1';
			wren_b		: in  STD_LOGIC := '0';
			q_b			: out STD_LOGIC_VECTOR (data_width_b-1 DOWNTO 0);
			cs_b        : in  std_logic := '1'
		);
	END component;
BEGIN
	ram : component dpram_dif generic map(addr_width,data_width,addr_width,data_width,mem_init_file)
	port map(clock,address_a,data_a,enable_a,wren_a,q_a,cs_a,address_b,data_b,enable_b,wren_b,q_b,cs_b);
END SYN;