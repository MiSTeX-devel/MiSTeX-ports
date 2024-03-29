--------------------------------------------------------------
-- Dual port Block RAM different parameters on ports
--------------------------------------------------------------
-- This file is the port of a part of upstream/rtl/bram.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;


entity dpram_dif is
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
end entity;

architecture syn_dif of dpram_dif is
    constant DEPTH_A      :  positive := 2**addr_width_a;
    constant BITS_A       :  positive := DEPTH_A * data_width_a;
	subtype  word_t_a     is std_logic_vector(data_width_a - 1 downto 0);
	type	 ram_t_a	  is array(0 to DEPTH_A - 1) of word_t_a;

    constant DEPTH_B      :  positive := 2**addr_width_b;
    constant BITS_B       :  positive := DEPTH_B * data_width_b;
	subtype  word_t_b     is std_logic_vector(data_width_b - 1 downto 0);
	type	 ram_t_b	  is array(0 to DEPTH_B - 1) of word_t_b;

	signal q0 : std_logic_vector((data_width_a - 1) downto 0);
	signal q1 : std_logic_vector((data_width_b - 1) downto 0);

begin
	q_a <= q0 when cs_a = '1' else (others => '1');
	q_b <= q1 when cs_b = '1' else (others => '1');

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
        MEMORY_INIT_FILE => mem_init_file,     -- String
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
        WRITE_PROTECT => 0                     -- DECIMAL
    )
    port map (
        -- dbiterra => dbiterra,             -- 1-bit output: Status signal to indicate double bit error occurrence
        -- dbiterrb => dbiterrb,             -- 1-bit output: Status signal to indicate double bit error occurrence

        douta => q0,                         -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
        doutb => q1,                         -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        -- sbiterra => sbiterra,             -- 1-bit output: Status signal to indicate single bit error occurrence
        -- sbiterrb => sbiterrb,             -- 1-bit output: Status signal to indicate single bit error occurrence
        addra => address_a,                  -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
        addrb => address_b,                  -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
        clka => clock,                       -- 1-bit input: Clock signal for port A. Also clocks port B when
        clkb => clock,                       -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
        dina => data_a,                      -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
        dinb => data_b,                      -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
        ena => enable_a,                     -- 1-bit input: Memory enable signal for port A.
        enb => enable_b,                     -- 1-bit input: Memory enable signal for port B.
        injectdbiterra => '0',               -- 1-bit input: Controls double bit error injection on input data
        injectdbiterrb => '0',               -- 1-bit input: Controls double bit error injection on input data
        injectsbiterra => '0',               -- 1-bit input: Controls single bit error injection on input data
        injectsbiterrb => '0',               -- 1-bit input: Controls single bit error injection on input data
        regcea => '1',                       -- 1-bit input: Clock Enable for the last register stage on the output data path.
        regceb => '1',                       -- 1-bit input: Clock Enable for the last register stage on the output data path.
        rsta   => '0',                       -- 1-bit input: Reset signal for the final port A output register
        rstb   => '0',                       -- 1-bit input: Reset signal for the final port B output register
        sleep  => '0',                       -- 1-bit input: sleep signal to enable the dynamic power saving feature.
        wea => (others => wren_a),           -- WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                             -- for port A input data port dina. 1 bit wide when word-wide writes
                                             -- are used. 
        web => (others => wren_b)            -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                             -- for port B input data port dinb. 1 bit wide when word-wide writes
                                             -- are used. 
    );
end architecture;