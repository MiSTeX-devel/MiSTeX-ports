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

Library xpm;
use xpm.vcomponents.all;

entity true_dual_port_ram is
  generic (
    ADDR_WIDTH_A : natural := 8;
    ADDR_WIDTH_B : natural := 8;
    DATA_WIDTH_A : natural := 8;
    DATA_WIDTH_B : natural := 8
  );
  port (
    -- port A
    clk_a  : in std_logic;
    cs_a   : in std_logic := '1';
    addr_a : in unsigned(ADDR_WIDTH_A-1 downto 0);
    din_a  : in std_logic_vector(DATA_WIDTH_A-1 downto 0) := (others => '0');
    dout_a : out std_logic_vector(DATA_WIDTH_A-1 downto 0);
    we_a   : in std_logic := '0';

    -- port B
    clk_b  : in std_logic;
    cs_b   : in std_logic := '1';
    addr_b : in unsigned(ADDR_WIDTH_B-1 downto 0);
    din_b  : in std_logic_vector(DATA_WIDTH_B-1 downto 0) := (others => '0');
    dout_b : out std_logic_vector(DATA_WIDTH_B-1 downto 0);
    we_b   : in std_logic := '0'
  );
end true_dual_port_ram;

architecture arch of true_dual_port_ram is
  signal   q_a      : std_logic_vector(DATA_WIDTH_A-1 downto 0);
  signal   q_b      : std_logic_vector(DATA_WIDTH_B-1 downto 0);
  constant DEPTH_A  :  positive := 2**addr_width_a;
  constant BITS_A   :  positive := DEPTH_A * data_width_a;
  subtype  word_t_a is std_logic_vector(data_width_a - 1 downto 0);
  type     ram_t_a	is array(0 to DEPTH_A - 1) of word_t_a;

  constant DEPTH_B  :  positive := 2**addr_width_b;
  constant BITS_B   :  positive := DEPTH_B * data_width_b;
  subtype  word_t_b is std_logic_vector(data_width_b - 1 downto 0);
  type	   ram_t_b  is array(0 to DEPTH_B - 1) of word_t_b;

  signal q0 : std_logic_vector((data_width_a - 1) downto 0);
  signal q1 : std_logic_vector((data_width_b - 1) downto 0);

  signal we_std_a : std_logic_vector(0 downto 0);
  signal we_std_b : std_logic_vector(0 downto 0);

begin
  dout_a <= q0 when cs_a = '1' else (others => '1');
  dout_b <= q1 when cs_b = '1' else (others => '1');
  we_std_a <= (0 => we_a);
  we_std_b <= (0 => we_b);

  assert BITS_A = BITS_B report "both memory ports must address the same memory size in bits" severity error;

  -- xpm_memory_tdpram: True Dual Port RAM
  -- Xilinx Parameterized Macro, version 2022.2

  xpm_memory_tdpram_inst : xpm_memory_tdpram
  generic map (
      ADDR_WIDTH_A => addr_width_a,          -- DECIMAL
      ADDR_WIDTH_B => addr_width_b,          -- DECIMAL
      AUTO_SLEEP_TIME => 0,                  -- DECIMAL
      BYTE_WRITE_WIDTH_A => data_width_a,    -- DECIMAL
      BYTE_WRITE_WIDTH_B => data_width_b,    -- DECIMAL
      CASCADE_HEIGHT => 0,                   -- DECIMAL
      CLOCKING_MODE => "common_clock",       -- String
      ECC_MODE => "no_ecc",                  -- String
      MEMORY_INIT_FILE => "none",            -- String
      MEMORY_INIT_PARAM => "0",              -- String
      MEMORY_OPTIMIZATION => "true",         -- String
      MEMORY_PRIMITIVE => "auto",            -- String
      MEMORY_SIZE => BITS_A,                 -- DECIMAL
      MESSAGE_CONTROL => 0,                  -- DECIMAL
      READ_DATA_WIDTH_A => data_width_a,     -- DECIMAL
      READ_DATA_WIDTH_B => data_width_b,     -- DECIMAL
      READ_LATENCY_A => 0,                   -- DECIMAL
      READ_LATENCY_B => 0,                   -- DECIMAL
      READ_RESET_VALUE_A => "0",             -- String
      READ_RESET_VALUE_B => "0",             -- String
      RST_MODE_A => "SYNC",                  -- String
      RST_MODE_B => "SYNC",                  -- String
      SIM_ASSERT_CHK => 0,                   -- DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      USE_EMBEDDED_CONSTRAINT => 0,          -- DECIMAL
      USE_MEM_INIT => 0,                     -- DECIMAL
      USE_MEM_INIT_MMI => 0,                 -- DECIMAL
      WAKEUP_TIME => "disable_sleep",        -- String
      WRITE_DATA_WIDTH_A => data_width_a,    -- DECIMAL
      WRITE_DATA_WIDTH_B => data_width_b,    -- DECIMAL
      WRITE_MODE_A => "write_first",         -- String
      WRITE_MODE_B => "write_first",         -- String
      WRITE_PROTECT => 1                     -- DECIMAL
  )
  port map (
      -- dbiterra => dbiterra,             -- 1-bit output: Status signal to indicate double bit error occurrence
      -- dbiterrb => dbiterrb,             -- 1-bit output: Status signal to indicate double bit error occurrence

      douta => q0,                         -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      doutb => q1,                         -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
      -- sbiterra => sbiterra,             -- 1-bit output: Status signal to indicate single bit error occurrence
      -- sbiterrb => sbiterrb,             -- 1-bit output: Status signal to indicate single bit error occurrence
      addra => std_logic_vector(addr_a),   -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      addrb => std_logic_vector(addr_b),   -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
      clka => clk_a,                       -- 1-bit input: Clock signal for port A. Also clocks port B when
      clkb => clk_b,                       -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
      dina => din_a,                       -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      dinb => din_b,                       -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
      ena => cs_a,                         -- 1-bit input: Memory enable signal for port A.
      enb => cs_b,                         -- 1-bit input: Memory enable signal for port B.
      injectdbiterra => '0',               -- 1-bit input: Controls double bit error injection on input data
      injectdbiterrb => '0',               -- 1-bit input: Controls double bit error injection on input data
      injectsbiterra => '0',               -- 1-bit input: Controls single bit error injection on input data
      injectsbiterrb => '0',               -- 1-bit input: Controls single bit error injection on input data
      regcea => '1',                       -- 1-bit input: Clock Enable for the last register stage on the output data path.
      regceb => '1',                       -- 1-bit input: Clock Enable for the last register stage on the output data path.
      rsta   => '0',                       -- 1-bit input: Reset signal for the final port A output register
      rstb   => '0',                       -- 1-bit input: Reset signal for the final port B output register
      sleep  => '0',                       -- 1-bit input: sleep signal to enable the dynamic power saving feature.
      wea => we_std_a,       
           -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                           -- for port A input data port dina. 1 bit wide when word-wide writes
                                           -- are used. 
      web => we_std_b             -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                           -- for port B input data port dinb. 1 bit wide when word-wide writes
                                           -- are used. 
  );
end architecture arch;
