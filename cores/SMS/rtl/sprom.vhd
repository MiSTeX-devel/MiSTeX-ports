library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

USE work.eprom_pack.all;

ENTITY sprom IS
	GENERIC
	(
		widthad_a		  : natural := 14;
		width_a			  : natural := 8
	);
	PORT
	(
		address		: IN STD_LOGIC_VECTOR (widthad_a-1 DOWNTO 0);
		clock		: IN STD_LOGIC ;
		q		    : OUT STD_LOGIC_VECTOR (width_a-1 DOWNTO 0)
	);
END sprom;


ARCHITECTURE SYN OF sprom IS
BEGIN
	process (clock)
	begin 
		if rising_edge(clock) then
			q <= eprom_rom(conv_integer(address));
		end if;
	end process;
END SYN;
