library	IEEE;
use		IEEE.std_logic_1164.all;
use		IEEE.numeric_std.all;

entity sys_dpram is
	generic (
		 widthad_a : integer := 8;
		 width_a   : integer := 8
	); 
	PORT
	(
		address_a	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		address_b	: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		clock_a		: IN STD_LOGIC  := '1';
		clock_b		: IN STD_LOGIC ;
		data_a		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		data_b		: IN STD_LOGIC_VECTOR (width_a-1 DOWNTO 0) := (others => '0');
		enable_a    : IN STD_LOGIC  := '1';
		enable_b    : IN STD_LOGIC  := '1';
		wren_a		: IN STD_LOGIC  := '0';
		wren_b		: IN STD_LOGIC  := '0';
		q_a			: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0);
		q_b			: OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END sys_dpram;

architecture syn of sys_dpram is
    constant DEPTH        :  positive := 2**widthad_a;
	subtype  word_t	      is std_logic_vector(width_a - 1 downto 0);
	type	 ram_t		  is array(0 to DEPTH - 1) of word_t;
    signal   ram          :  ram_t;
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
end architecture;
