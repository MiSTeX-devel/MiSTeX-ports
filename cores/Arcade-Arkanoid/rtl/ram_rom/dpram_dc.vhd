LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY dpram_dc IS
	GENERIC
	(
		init_file			: string := " ";
		widthad_a			: natural;
		width_a				: natural := 8;
		outdata_reg_a       : string := "UNREGISTERED";
		outdata_reg_b       : string := "UNREGISTERED"
	);
	PORT
	(
		address_a   : IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		address_b   : IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0) := (others => '0');
		clock_a     : IN STD_LOGIC ;
		clock_b     : IN STD_LOGIC ;
		data_a      : IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0) := (others => '0');
		data_b      : IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0) := (others => '0');
		wren_a      : IN STD_LOGIC  := '0';
		wren_b      : IN STD_LOGIC  := '0';
		byteena_a   : IN STD_LOGIC_VECTOR (width_a/8-1 DOWNTO 0) := (others => '1');
		byteena_b   : IN STD_LOGIC_VECTOR (width_a/8-1 DOWNTO 0) := (others => '1');
		q_a         : OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		q_b         : OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END dpram_dc;


ARCHITECTURE SYN OF dpram_dc IS
constant DEPTH        : positive := 2**widthad_a;
constant enable_a     : std_logic := '1';
constant enable_b     : std_logic := '1';
subtype  word_t	      is std_logic_vector(width_a - 1 downto 0);
type	 ram_t		  is array(0 to DEPTH - 1) of word_t;
signal   ram          : ram_t;
begin
	process (clock_a, clock_b)
	begin
		if rising_edge(clock_a) then
			if enable_a = '1' then
				if wren_a = '1' then
					ram(to_integer(unsigned(address_a))) <= data_a;
					q_a <= data_a;
				else
					q_a <= ram(to_integer(unsigned(address_a)));
				end if;
			end if;
		end if;
		if rising_edge(clock_b) then
			if enable_b = '1' then
				if wren_b = '1' then
					ram(to_integer(unsigned(address_b))) <= data_b;
					q_b <= data_b;
				else
					q_b <= ram(to_integer(unsigned(address_b)));
				end if;
			end if;
		end if;
	end process;
END SYN;
