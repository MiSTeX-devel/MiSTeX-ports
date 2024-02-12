library	IEEE;
use		IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;

entity spram is
	generic (
		 widthad_a : integer := 14;
		 width_a   : integer := 8
	); 
	PORT
	(
		address	    : IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		clock		: IN STD_LOGIC;
		data		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		wren		: IN STD_LOGIC;
		q			: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END spram;

architecture syn of spram is
    constant DEPTH        :  positive := 2**widthad_a;
	subtype  word_t	      is std_logic_vector(width_a - 1 downto 0);
	type	 ram_t		  is array(0 to DEPTH - 1) of word_t;
    signal   ram          :  ram_t;
begin
	process (clock)
	begin
		if rising_edge(clock) then
			if wren = '1' then
				ram(to_integer(unsigned(address))) <= data;
				q <= data;
			else
				q <= ram(to_integer(unsigned(address)));
			end if;
		end if;
	end process;
end architecture;
