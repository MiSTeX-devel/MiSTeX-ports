--   __   __     __  __     __         __
--  /\ "-.\ \   /\ \/\ \   /\ \       /\ \
--  \ \ \-.  \  \ \ \_\ \  \ \ \____  \ \ \____
--   \ \_\\"\_\  \ \_____\  \ \_____\  \ \_____\
--    \/_/ \/_/   \/_____/   \/_____/   \/_____/
--   ______     ______       __     ______     ______     ______
--  /\  __ \   /\  == \     /\ \   /\  ___\   /\  ___\   /\__  _\
--  \ \ \/\ \  \ \  __<    _\_\ \  \ \  __\   \ \ \____  \/_/\ \/
--   \ \_____\  \ \_____\ /\_____\  \ \_____\  \ \_____\    \ \_\
--    \/_____/   \/_____/ \/_____/   \/_____/   \/_____/     \/_/
--
-- https://joshbassett.info
-- https://twitter.com/nullobject
-- https://github.com/nullobject
--
-- Copyright (c) 2020 Josh Bassett
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity single_port_ram is
  generic (
    ADDR_WIDTH : natural := 8;
    DATA_WIDTH : natural := 8
  );
  port (
    -- clk
    clk : in std_logic;

    -- chip select
    cs : in std_logic := '1';

    -- address
    addr : in unsigned(ADDR_WIDTH-1 downto 0);

    -- data in
    din : in std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

    -- data out
    dout : out std_logic_vector(DATA_WIDTH-1 downto 0);

    -- write enable
    we : in std_logic := '0'
  );
end single_port_ram;

architecture arch of single_port_ram is
  signal   q      : std_logic_vector(DATA_WIDTH-1 downto 0);
  constant DEPTH  : positive  := 2**ADDR_WIDTH;
	subtype  word_t	is std_logic_vector(DATA_WIDTH - 1 downto 0);
	type	   ram_t	is array(0 to DEPTH - 1) of word_t;
  signal   ram    :  ram_t;

begin
	process (clk)
	begin
		if rising_edge(clk) then
      if cs = '1' and we = '1' then
        ram(to_integer(unsigned(addr))) <= din;
        q <= din;
      end if;
      q <= ram(to_integer(unsigned(addr)));
    end if;
	end process;

  dout <= q when cs = '1' else (others => '0');
end architecture arch;
