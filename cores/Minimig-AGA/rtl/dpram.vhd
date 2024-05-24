--------------------------------------------------------------
-- Dual port Block RAM same parameters on both ports
--------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE std.textio.all;

entity dpram is
	generic (
		addr_width    : integer := 8;
		data_width    : integer := 8;
		mem_init_file : string := " "
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
subtype  word_t	      is std_logic_vector(data_width - 1 downto 0);
constant numwords     :  integer := 2**addr_width;		
type	 ram_t		  is array(0 to numwords - 1) of word_t;

signal   write_enable : std_logic;

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

shared variable  ram                : ram_t := init_from_file_or_zeroes(mem_init_file);
attribute        ram_style          : string;
attribute        ram_style of ram   : variable is "block";

signal   q_0 :  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);
signal   q_1 :  STD_LOGIC_VECTOR (data_width-1 DOWNTO 0);

begin

q_a <= q_0 when cs_a = '1' else (others => '1');
q_b <= q_1 when cs_b = '1' else (others => '1');
		
process (clock)
begin
	if rising_edge(clock) then
		if enable_a = '1' then
			if wren_a = '1' then
				ram(to_integer(unsigned(address_a))) := data_a;
				q_0 <= data_a;
			else
				q_0 <= ram(to_integer(unsigned(address_a)));
			end if;
		end if;
	end if;
end process;
process (clock)
begin
	if rising_edge(clock) then	
		if enable_b = '1' then
			if wren_b = '1' then
				ram(to_integer(unsigned(address_b))) := data_b;
				q_1 <= data_b;
			else
				q_1 <= ram(to_integer(unsigned(address_b)));
			end if;
		end if;
	end if;
end process;
END SYN;