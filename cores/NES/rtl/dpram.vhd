library	IEEE;
use		IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;
use     STD.textio.all;

entity dpram is
	generic (
		 init_file : string := " ";
		 widthad_a : natural;
		 width_a   : natural := 8
	); 
	PORT
	(
		address_a	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0) := (others => '0');
		clock_a		: IN STD_LOGIC ;
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0) := (others => '0');
		data_b		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0) := (others => '0');
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		-- byteena are unused, we just ignore them
		byteena_a	: IN STD_LOGIC_VECTOR (width_a/8-1 DOWNTO 0) := (others => '1');
		byteena_b	: IN STD_LOGIC_VECTOR (width_a/8-1 DOWNTO 0) := (others => '1');
		q_a			: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		q_b			: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END dpram;

architecture syn of dpram is
    constant DEPTH  :  positive := 2**widthad_a;
	subtype  word_t	is std_logic_vector(width_a - 1 downto 0);
	type	 ram_t	is array(0 to DEPTH - 1) of word_t;
   
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

    shared variable  ram : ram_t := init_from_file_or_zeroes(init_file);
	attribute ram_style          : string;
	attribute ram_style of ram   : variable is "block";

begin
	process (clock_a)
	begin
		if rising_edge(clock_a) then
			if wren_a = '1' then
				ram(to_integer(unsigned(address_a))) := data_a;
				q_a <= data_a;
			else
				q_a <= ram(to_integer(unsigned(address_a)));
			end if;
		end if;
	end process;
	process (clock_b)
	begin
		if rising_edge(clock_b) then
			if wren_b = '1' then
				ram(to_integer(unsigned(address_b))) := data_b;
				q_b <= data_b;
			else
				q_b <= ram(to_integer(unsigned(address_b)));
			end if;
		end if;
	end process;
end architecture;
