--	(c) 2012 d18c7db(a)hotmail
--
--	This program is free software; you can redistribute it and/or modify it under
--	the terms of the GNU General Public License version 3 or, at your option,
--	any later version as published by the Free Software Foundation.
--
--	This program is distributed in the hope that it will be useful,
--	but WITHOUT ANY WARRANTY; without even the implied warranty of
--	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--
-- For full details, see the GNU General Public License at www.gnu.org/licenses

-- ###########################################################################
-- ##### PAGE 9 schema - CPU + RAM + ROM + glue logic                    #####
-- ###########################################################################

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.std_logic_arith.all;

--use work.bj_package.all;

entity audio is
	port (
		clk_48M     : in  std_logic;
		dn_addr     : in  std_logic_vector(16 downto 0);
		dn_data     : in  std_logic_vector(7 downto 0);
		dn_wr       : in  std_logic;

		I_CLK_12M	: in  std_logic;
		I_CLK_EN		: in  std_logic;
		I_RESET_n	: in  std_logic;
		I_VSYNC_n	: in  std_logic;
		I_CS_B800_n	: in  std_logic;
		I_MERW_n		: in  std_logic;
		I_DB_CPU		: in  std_logic_vector( 7 downto 0);
		I_SD			: in  std_logic_vector( 7 downto 0);
		O_SD			: out std_logic_vector( 7 downto 0);
		O_SA0			: out std_logic;
		O_PSG1_n		: out std_logic;
		O_PSG2_n		: out std_logic;
		O_PSG3_n		: out std_logic;
		O_SWR_n		: out std_logic;
		O_SRD_n		: out std_logic
	);
end audio;

architecture RTL of audio is
	component dpram is
		generic (
			 addr_width_g : integer := 8;
			 data_width_g : integer := 8
		); 
		PORT
		(
			address_a	: IN STD_LOGIC_VECTOR (addr_width_g-1 DOWNTO 0);
			address_b	: IN STD_LOGIC_VECTOR (addr_width_g-1 DOWNTO 0);
			clock_a		: IN STD_LOGIC  := '1';
			clock_b		: IN STD_LOGIC ;
			data_a		: IN STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0);
			data_b		: IN STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0) := (others => '0');
			enable_a    : IN STD_LOGIC  := '1';
			enable_b    : IN STD_LOGIC  := '1';
			wren_a		: IN STD_LOGIC  := '0';
			wren_b		: IN STD_LOGIC  := '0';
			q_a			: OUT STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0);
			q_b			: OUT STD_LOGIC_VECTOR (data_width_g-1 DOWNTO 0)
		);
	END component;

	signal cpu_addr			: std_logic_vector(15 downto 0) := (others => '0');
	signal cpu_data_in		: std_logic_vector( 7 downto 0) := (others => '0');
	signal cpu_data_out		: std_logic_vector( 7 downto 0) := (others => '0');
	signal rom_3H_data		: std_logic_vector( 7 downto 0) := (others => '0');
--	signal rom_3J_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_2L_bus			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ram_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_b800_wr_n_t0	: std_logic := '1';
	signal s_b800_wr_n_t1	: std_logic := '1';
	signal s_b800_wr_n_re	: std_logic := '1';
	signal s_60H_n				: std_logic := '1';
	signal s_sram				: std_logic := '0';
	signal s_srom1				: std_logic := '0';
--	signal s_srom2				: std_logic := '0';
	signal s_srd_n				: std_logic := '1';
	signal s_swr				: std_logic := '0';
	signal s_swr_n				: std_logic := '1';
	signal s_mreq_n			: std_logic := '1';
	signal s_iorq_n			: std_logic := '1';
	signal s_2F3_t0			: std_logic := '0';
	signal s_2F3_t1			: std_logic := '0';
	signal s_2F3_re			: std_logic := '0';
	signal s_2F6				: std_logic := '0';
	signal s_2J6_n				: std_logic := '1';
	signal s_2J8_n				: std_logic := '1';
	signal s_2M3_n				: std_logic := '1';
	signal s_vsync_n_t0		: std_logic := '0';
	signal s_vsync_n_t1		: std_logic := '0';
	signal s_vsync_n_re		: std_logic := '0';

	signal ROM_3H_cs        : std_logic;

begin

	-- outputs to PSG board
	O_SD		<= cpu_data_out;
	O_SA0		<= cpu_addr(0);
	O_SWR_n	<= s_swr_n;
	O_SRD_n	<= s_srd_n;

	-- PSG selector
	O_PSG3_n  <= not ( (not s_iorq_n) and (    cpu_addr(7)) and (not cpu_addr(4)) );
	O_PSG2_n  <= not ( (not s_iorq_n) and (not cpu_addr(7)) and (    cpu_addr(4)) );
	O_PSG1_n  <= not ( (not s_iorq_n) and (not cpu_addr(7)) and (not cpu_addr(4)) );

	s_swr <= not s_swr_n;

	-- chip 5D page 9
	s_60H_n <= not ( (not s_mreq_n) and (    cpu_addr(14)) and (    cpu_addr(13)) );
	-- we actually need these inverted due to active high chip selects
	s_sram  <=     ( (not s_mreq_n) and (    cpu_addr(14)) and (not cpu_addr(13)) );
--	s_srom2 <=     ( (not s_mreq_n) and (not cpu_addr(14)) and (    cpu_addr(13)) );
	s_srom1 <=     ( (not s_mreq_n) and (not cpu_addr(14)) and (not cpu_addr(13)) );

	-- chip 2M3
	s_2M3_n <= I_RESET_n and s_60H_n;

	-- generate clock enables for 12M
	gen_clken : process
	begin
		wait until rising_edge(I_CLK_12M);

		-- chip 2F3
		s_2F3_t1 <= s_2F3_t0;
		s_2F3_t0 <= s_srd_n or s_60H_n;

		-- chip 3N6 page 2
		s_b800_wr_n_t1 <= s_b800_wr_n_t0;
		s_b800_wr_n_t0 <= I_MERW_n or I_CS_B800_n; -- /B800H on schema page 2

		-- rising edge of VSYNC
		s_vsync_n_t1 <= s_vsync_n_t0;
		s_vsync_n_t0 <= I_VSYNC_n;
	end process;

	-- rising edges
	s_2F3_re       <= s_2F3_t0 and not s_2F3_t1;
	s_vsync_n_re   <= s_vsync_n_t0 and not s_vsync_n_t1;
	s_b800_wr_n_re <= s_b800_wr_n_t0 and not s_b800_wr_n_t1;

	-- chip 2F6
	s_2F6 <= I_CLK_EN or s_2J6_n;

	-- chip 2J6 page 9
	U2J6 : process(I_CLK_12M, s_2F6)
	begin
		if s_2F6 = '0' then
			s_2J6_n <= '1';
		elsif rising_edge(I_CLK_12M) then
			if (s_2F3_re = '1') then
				s_2J6_n <= '0';
			end if;
		end if;
	end process;

	-- chip 2J8 page 9
	-- F/F clock not labeled on schema, determined to be /vsync
	U2J8 : process(I_CLK_12M, s_2M3_n)
	begin
		if s_2M3_n = '0' then
			s_2J8_n <= '1';
		elsif rising_edge(I_CLK_12M) then
			if (s_vsync_n_re = '1') then
				s_2J8_n <= '0';
			end if;
		end if;
	end process;

	-- chip 2L page 9
	U2L : process(I_CLK_12M, s_2J6_n)
	begin
		if s_2J6_n = '0' then
			s_2L_bus <= (others => '0');
		elsif rising_edge(I_CLK_12M) then
			if (s_b800_wr_n_re = '1') then
				s_2L_bus <= I_DB_CPU;
			end if;
		end if;
	end process;

	-- CPU data bus mux
	cpu_data_in <=
		s_2L_bus    when (s_2F3_t0 = '0') else
		ram_data    when (s_sram   = '1') else
		rom_3H_data when (s_srom1  = '1') else
--		rom_3J_data when (s_srom2  = '1') else
		I_SD;

	-- CPU RAM 
	-- chip 3K page 9
	ram_3K : entity work.ram_3k
	port map (
		address		=> cpu_addr(10 downto 0),
	        clock		=> I_CLK_12M,
	        clken		=> s_sram,
	        data		=> cpu_data_out,
	        wren		=> s_swr,
	        q		=> ram_data
	);

	ROM_3H_cs <= '1' when dn_addr(16 downto 13) = X"0" else '0';

	ROM_3H : component dpram generic map (13,8)
	port map
	(
		clock_a   => clk_48M,
		wren_a    => dn_wr and ROM_3H_cs,
		address_a => dn_addr(12 downto 0),
		data_a    => dn_data,

		clock_b   => I_CLK_12M,
		enable_b  => s_srom1,
		address_b => cpu_addr(12 downto 0),
		q_b       => rom_3H_data
	);

--	-- chip 3J page 9 (not fitted to board, empty socket)

	-- Z80 CPU on sound board
	-- chip 34F page 9
	cpu_34F : entity work.T80sed
		port map (
			-- inputs
			DI      => cpu_data_in,
			RESET_n => I_RESET_n,
			CLK_n   => I_CLK_12M,
			CLKEN   => I_CLK_EN,			-- 3Mhz clock enable
			INT_n   => '1',
			WAIT_n  => '1',
			BUSRQ_n => '1',
			NMI_n   => s_2J8_n,
			-- outputs
			MREQ_n  => s_mreq_n,
			RD_n    => s_srd_n,
			WR_n    => s_swr_n,
			A       => cpu_addr,
			DO      => cpu_data_out,
			RFSH_n  => open,
			M1_n    => open,
			IORQ_n  => s_iorq_n,
			HALT_n  => open,
			BUSAK_n => open
		);

end RTL;
