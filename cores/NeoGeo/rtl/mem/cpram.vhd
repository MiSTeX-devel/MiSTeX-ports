--------------------------------------------------------------
-- Dual port Block RAM different parameters on ports
--------------------------------------------------------------
-- This file is the port of a part of upstream/rtl/bram.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

entity cpram is
	PORT
	(
		clock		: IN STD_LOGIC;
		reset		: IN STD_LOGIC;
		wr  		: IN STD_LOGIC;
		data		: IN STD_LOGIC_VECTOR (63 DOWNTO 0);
		rd  		: IN STD_LOGIC;
		q			: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END cpram;

architecture syn of cpram is
    constant addr_width    : positive := 7;
    constant addr_width_b  : positive := 9;
    constant data_width    : positive := 64;
    constant data_width_b  : positive := 16;
    constant MEM_SIZE_BITS : positive := 2**addr_width * data_width;
    signal rdaddress : unsigned (addr_width_b-1   downto 0);
    signal wraddress : unsigned (addr_width-1 downto 0);

begin
    -- xpm_memory_tdpram: True Dual Port RAM
    -- Xilinx Parameterized Macro, version 2022.2

    process (clock) begin
        if wr = '1' then
            wraddress <= wraddress + 1;
            rdaddress <= (others => '0');
        end if;
        if rd = '1' then
            rdaddress <= rdaddress + 1;
            wraddress <= (others => '0');
        end if;
        if reset = '1' then
            rdaddress <= (others => '0');
            wraddress <= (others => '0');
        end if;
    end process;

    xpm_memory_tdpram_inst : xpm_memory_tdpram
    generic map (
        ADDR_WIDTH_A => addr_width,          -- DECIMAL
        ADDR_WIDTH_B => addr_width_b,          -- DECIMAL
        AUTO_SLEEP_TIME => 0,                  -- DECIMAL
        BYTE_WRITE_WIDTH_A => data_width,    -- DECIMAL
        BYTE_WRITE_WIDTH_B => data_width_b,    -- DECIMAL
        CASCADE_HEIGHT => 0,                   -- DECIMAL
        CLOCKING_MODE => "common_clock",       -- String
        ECC_MODE => "no_ecc",                  -- String
        MEMORY_INIT_FILE => "none",            -- String
        MEMORY_INIT_PARAM => "0",              -- String
        MEMORY_OPTIMIZATION => "true",         -- String
        MEMORY_PRIMITIVE => "auto",            -- String
        MEMORY_SIZE => MEM_SIZE_BITS,          -- DECIMAL
        MESSAGE_CONTROL => 0,                  -- DECIMAL
        READ_DATA_WIDTH_A => data_width,     -- DECIMAL
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
        WRITE_DATA_WIDTH_A => data_width,     -- DECIMAL
        WRITE_DATA_WIDTH_B => data_width_b,     -- DECIMAL
        WRITE_MODE_A    => "write_first",         -- String
        WRITE_MODE_B  => "write_first",         -- String
        WRITE_PROTECT => 1                     -- DECIMAL
    )
    port map (
        douta => open,                         -- READ_DATA_WIDTH-bit output: Data output for port A read operations.
        doutb => q,                            -- READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
        addra => std_logic_vector(wraddress),  -- ADDR_WIDTH-bit input: Address for port A write and read operations.
        addrb => std_logic_vector(rdaddress),  -- ADDR_WIDTH_B-bit input: Address for port B write and read operations.
        clka => clock,                         -- 1-bit input: Clock signal for port A. Also clocks port B when
        clkb => clock,                         -- 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
        dina => data,                      -- WRITE_DATA_WIDTH-bit input: Data input for port A write operations.
        dinb => (others => '1'),                      -- WRITE_DATA_WIDTH_B-bit input: Data input for port B write operations.
        ena => '1',                     -- 1-bit input: Memory enable signal for port A.
        enb => '1',                     -- 1-bit input: Memory enable signal for port B.
        wea => (others => wr),               -- WRITE_DATA_WIDTH/BYTE_WRITE_WIDTH-bit input: Write enable vector
                                             -- for port A input data port dina. 1 bit wide when word-wide writes
                                             -- are used. 
        web => (others => '0'),               -- WRITE_DATA_WIDTH_B/BYTE_WRITE_WIDTH_B-bit input: Write enable vector
                                             -- for port B input data port dinb. 1 bit wide when word-wide writes
                                             -- are used. 
        injectdbiterra => '0',               -- 1-bit input: Controls double bit error injection on input data
        injectdbiterrb => '0',               -- 1-bit input: Controls double bit error injection on input data
        injectsbiterra => '0',               -- 1-bit input: Controls single bit error injection on input data
        injectsbiterrb => '0',               -- 1-bit input: Controls single bit error injection on input data
        regcea => '1',                 -- 1-bit input: Clock Enable for the last register stage on the output
        regceb => '1',                 -- 1-bit input: Clock Enable for the last register stage on the output
        rsta   => '0',                     -- 1-bit input: Reset signal for the final port A output register
        rstb   => '0',                     -- 1-bit input: Reset signal for the final port B output register
        sleep  => '0'                          -- 1-bit input: sleep signal to enable the dynamic power saving feature.                                     
    );
end architecture;