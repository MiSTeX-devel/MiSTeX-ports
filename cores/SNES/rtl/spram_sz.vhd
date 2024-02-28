--------------------------------------------------------------
-- Single port Block RAM with specific size
--------------------------------------------------------------
-- This file is the port of a part of upstream/rtl/bram.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE std.textio.all;

ENTITY spram_sz IS
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
		q       : out STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
		cs      : in  std_logic := '1'
	);
END ENTITY;

architecture syn_sz of spram_sz is
	subtype  word_t	      is std_logic_vector(data_width - 1 downto 0);
	type	 ram_t		  is array(0 to numwords - 1) of word_t;

	signal   write_enable : std_logic;
	signal   q0           : std_logic_vector((data_width - 1) downto 0);

	function InitRamFromFile (ramfilename : in string) return ram_t is
		file ramfile	     : text is in ramfilename;
		variable ramfileline : line;
		variable ram_name	 : ram_t;
		variable bitvec      : word_t;
	begin
		for i in ram_t'range loop
			readline (ramfile, ramfileline);
			hread    (ramfileline, bitvec);
			ram_name(i) := to_stdlogicvector(bitvec);
		end loop;
		return ram_name;
	end function;

	function init_from_file_or_zeroes(ramfile : string) return ram_t is
	begin
		if ramfile = " " then
			return (others => (others => '0'));
		else
			return InitRamFromFile(ramfile) ;
		end if;
	end;

    shared variable  ram : ram_t := init_from_file_or_zeroes(mem_init_file);

begin
	q <= q0 when cs = '1' else (others => '1');
	write_enable <= wren and cs;

	process (clock)
	begin
		if rising_edge(clock) then
			if write_enable = '1' then
				ram(to_integer(unsigned(address))) := data;
				q <= data;
			else
				q <= ram(to_integer(unsigned(address)));
			end if;
		end if;
	end process;
end architecture;