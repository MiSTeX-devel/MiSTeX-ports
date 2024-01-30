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

--------------------------------------------------------------------------------
--	This is a VHDL implementation of the arcade game "Bomb Jack" (c) 1984 Tehkan
--	Translated from schematic to VHDL Q1 2012, d18c7db
--
-- v0.1	Initial release
--
-- added testbed folder and moved all testbed related files into it
-- changed UCF to use Megawing
-- split audio file into p9/p10
-- fixed: sprites not showing, clock to sprite RAMS 4A,B,C,D had to be inverted
-- fixed: audio issue with PSG1 chan C, missing chip selects to RAM/ROM
-- fixed: Sometimes enemy robots get stuck inside a platform, clock to 6L,M had to be inverted
-- fixed: RAM4 fails self test, clock timing issue with 6L,M had to double clock frequency
-- fixed: Bomb Jack death animation sequence, wrongly inverting s_7C6 though 6M on page 4
-- fixed: 32x32 tiles not showing correclty when running from SRAM but correct when running from BRAM, SRAM state machine needed to run continuously
--
-- v0.8
--
-- fixed: color palette access contention between CPU and video, causing glitches to appear on a few scan lines between screen transitions
-- fixed: Last 8 pixels of the last video line not showing, can be observed quring squares test pattern (not visible in game)
--		this issue is due to /vblank signal rising too early (see page 8 chips 8B, 7A) clearing the video output while
--		there are still 8 pixels left to shift out. Extended the vblank signal to compensate, but this deviates from schemtatic.
--
--	Known Issues
--

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_arith.all;
	use ieee.std_logic_unsigned.all;
	use ieee.numeric_std.all;

entity BOMB_JACK is
	port(
		I_P1					: in		std_logic_vector( 7 downto 0);		-- input switches player 1
		I_P2					: in		std_logic_vector( 7 downto 0);		-- input switches player 2
		I_SYS					: in		std_logic_vector( 7 downto 0);		-- input switches system
		I_SW1					: in		std_logic_vector( 7 downto 0);		-- input switches presets 1
		I_SW2					: in		std_logic_vector( 7 downto 0);		-- input switches presets 2

		O_AUDIO				: out		std_logic_vector( 7 downto 0);

		-- VGA monitor output
		O_VIDEO_R			: out		std_logic_vector(3 downto 0);
		O_VIDEO_G			: out		std_logic_vector(3 downto 0);
		O_VIDEO_B			: out		std_logic_vector(3 downto 0);
		O_HSYNC				: out		std_logic;
		O_VSYNC				: out		std_logic;
		O_CMPBLK_n			: out		std_logic;

		O_VBLANK				: out		std_logic;
		O_HBLANK				: out		std_logic;

		-- ROMS
		I_ROM_4P_DATA		: in  std_logic_vector( 7 downto 0) := (others => '0');
		O_ROM_4P_ADDR		: out std_logic_vector(12 downto 0) := (others => '0');
		O_ROM_4P_ENA		: out std_logic := '1';
                          
		I_ROM_7JLM_DATA	: in  std_logic_vector(23 downto 0) := (others => '0');
		O_ROM_7JLM_ADDR	: out std_logic_vector(12 downto 0) := (others => '0');
		O_ROM_7JLM_ENA		: out std_logic := '1';
                          
		I_ROM_8KHE_DATA	: in  std_logic_vector(23 downto 0) := (others => '0');
		O_ROM_8KHE_ADDR	: out std_logic_vector(12 downto 0) := (others => '0');
		O_ROM_8KHE_ENA		: out std_logic := '1';
                          
		I_ROM_8RNL_DATA	: in  std_logic_vector(23 downto 0) := (others => '0');
		O_ROM_8RNL_ADDR	: out std_logic_vector(12 downto 0) := (others => '0');
		O_ROM_8RNL_ENA		: out std_logic := '1';

		-- Active high external buttons
		I_RESET				: in		std_logic;								-- push button

		clk_48M           : in  std_logic;
		dn_addr           : in  std_logic_vector(16 downto 0);
		dn_data           : in  std_logic_vector(7 downto 0);
		dn_wr             : in  std_logic;

		-- Clocks
		I_CLK_4M				: in	std_logic := '0';
		I_CLK_6M				: in	std_logic := '0';
		I_CLK_12M			: in	std_logic := '0';
		
		I_PAUSE				: in	std_logic := '0';
		
		-- HISCORE
		hs_address			: in  std_logic_vector(15 downto 0);
		hs_data_out			: out std_logic_vector(7 downto 0);
		hs_data_in			: in  std_logic_vector(7 downto 0);
		hs_write				: in  std_logic
;
		flip_screen			: in std_logic
	);
end BOMB_JACK;

architecture RTL of BOMB_JACK is

	-- ROM selectors in external RAM space
--	constant sel_3H			: std_logic_vector( 4 downto 0) := "0" & x"0"; -- audio CPU rom
	constant sel_4P			: std_logic_vector( 4 downto 0) := "0" & x"1"; -- graphics
	constant sel_8E			: std_logic_vector( 4 downto 0) := "0" & x"2"; -- chars 0
	constant sel_8H			: std_logic_vector( 4 downto 0) := "0" & x"3"; -- chars 1
	constant sel_8K			: std_logic_vector( 4 downto 0) := "0" & x"4"; -- chars 2
	constant sel_8L			: std_logic_vector( 4 downto 0) := "0" & x"5"; -- bg tiles 0
	constant sel_8N			: std_logic_vector( 4 downto 0) := "0" & x"6"; -- bg tiles 1
	constant sel_8R			: std_logic_vector( 4 downto 0) := "0" & x"7"; -- bg tiles 2
--	constant sel_1J			: std_logic_vector( 4 downto 0) := "0" & x"8"; -- main CPU prog rom 0
--	constant sel_1L			: std_logic_vector( 4 downto 0) := "0" & x"9"; -- main CPU prog rom 1
--	constant sel_1M			: std_logic_vector( 4 downto 0) := "0" & x"A"; -- main CPU prog rom 2
--	constant sel_1N			: std_logic_vector( 4 downto 0) := "0" & x"B"; -- main CPU prog rom 3
--	constant sel_1R			: std_logic_vector( 4 downto 0) := "0" & x"C"; -- main CPU prog rom 4
	constant sel_7J			: std_logic_vector( 4 downto 0) := "0" & x"D"; -- sprites 0
	constant sel_7L			: std_logic_vector( 4 downto 0) := "0" & x"E"; -- sprites 1
	constant sel_7M			: std_logic_vector( 4 downto 0) := "0" & x"F"; -- sprites 2

	-- video
	signal VideoR				: std_logic_vector(3 downto 0);
	signal VideoG				: std_logic_vector(3 downto 0);
	signal VideoB				: std_logic_vector(3 downto 0);
	signal HSync				: std_logic := '1';
	signal VSync				: std_logic := '1';

-- Bomb Jack signals
	signal clk_4M_en			: std_logic := '0';
	signal clk_6M_en			: std_logic := '0';
	signal clk_12M				: std_logic := '0';
	signal s_clk_en			: std_logic := '0';
	signal s_flip			: std_logic := '0';
	signal s_flip_switched		: std_logic := '0';
	signal s_merd_n			: std_logic := '1';
	signal s_mewr_n			: std_logic := '1';
	signal s_mewr				: std_logic := '0';
	signal s_cs_9000_n		: std_logic := '1';
	signal s_cs_9800_n		: std_logic := '1';
	signal s_cs_9a00_n		: std_logic := '1';
	signal s_cs_9c00_n		: std_logic := '1';
	signal s_cs_9e00_n		: std_logic := '1';
	signal s_cs_b000_n		: std_logic := '1';
	signal s_cs_b800_n		: std_logic := '1';
	signal cs_80_n				: std_logic := '0';
	signal cs_98_n				: std_logic := '0';

	signal s_red				: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_grn				: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_blu				: std_logic_vector( 3 downto 0) := (others => '0');
	signal dummy				: std_logic_vector( 3 downto 0) := (others => '0');

	-- player controls
	signal psg_data_out		: std_logic_vector( 7 downto 0) := (others => '0');
	signal psg_data_in		: std_logic_vector( 7 downto 0) := (others => '0');

	signal cpu_addr			: std_logic_vector(15 downto 0) := (others => '0');
	signal cpu_data_in		: std_logic_vector( 7 downto 0) := (others => '0');
	signal cpu_data_out		: std_logic_vector( 7 downto 0) := (others => '0');
	signal ram0_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal ram1_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal rom_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal io_data				: std_logic_vector( 7 downto 0) := (others => '0');
	signal rom_sel				: std_logic_vector( 4 downto 0) := (others => '0');
	signal wd_ctr				: std_logic_vector( 3 downto 0) := (others => '0');
	signal cpu_rd_n			: std_logic := '0';
	signal cpu_wr_n			: std_logic := '0';
	signal cpu_rfsh_n			: std_logic := '0';
	signal cpu_mreq_n			: std_logic := '0';
	signal cpu_reset_n		: std_logic := '0';
	signal RESETn				: std_logic := '1';

	signal s_wait				: std_logic := '0';
	signal s_wait_n			: std_logic := '1';
	signal s_wram0				: std_logic := '0';
	signal s_wram0_n			: std_logic := '1';
	signal s_wram1				: std_logic := '0';
	signal s_wram1_n			: std_logic := '1';
	signal s_ram0_n			: std_logic := '1';
	signal s_ram1_n			: std_logic := '1';
	signal s_ram2_n			: std_logic := '1';
	signal s_csen_n			: std_logic := '0';
	signal s_7P5				: std_logic := '0';
	signal s_7P9				: std_logic := '0';
	signal s_nmi_n				: std_logic := '1';
	signal s_nmion				: std_logic := '0';
	signal s_wdclr				: std_logic := '0';
	signal s_mhflip			: std_logic := '0';
	signal s_psg1_n			: std_logic := '0';
	signal s_psg2_n			: std_logic := '0';
	signal s_psg3_n			: std_logic := '0';
	signal s_swr_n				: std_logic := '0';
	signal s_srd_n				: std_logic := '0';
	signal s_sa0				: std_logic := '0';

	signal palette_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal sprite_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal char_data			: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_t_bus				: std_logic_vector( 4 downto 0) := (others => '0');
	signal s_4p_bus			: std_logic_vector( 8 downto 0) := (others => '0');
	signal s_5ef_bus			: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_6lm_bus			: std_logic_vector(10 downto 0) := (others => '0');
	signal s_6p_bus			: std_logic_vector( 2 downto 0) := (others => '0');
	signal s_oc					: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_ov					: std_logic_vector( 2 downto 0) := (others => '0');
	signal s_sc					: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_sv					: std_logic_vector( 2 downto 0) := (others => '0');
	signal s_bc					: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_bv					: std_logic_vector( 2 downto 0) := (others => '0');
	signal s_mc					: std_logic_vector( 3 downto 0) := (others => '0');
	signal s_mv					: std_logic_vector( 2 downto 0) := (others => '0');
	signal s_dac_out			: std_logic := '1';
	signal s_hsync_n			: std_logic := '1';
	signal s_cmpblk_n_r		: std_logic := '1';
	signal s_vblank_n			: std_logic := '1';
	signal s_vblank_t0		: std_logic := '1';
	signal s_vblank_t1		: std_logic := '1';
	signal s_cmpblk_n			: std_logic := '1';
	signal s_sw_n				: std_logic := '1';
	signal s_hbl				: std_logic := '0';
	signal s_vpl_n				: std_logic := '1';
	signal s_cdl_n				: std_logic := '1';
	signal s_mdl_n				: std_logic := '1';
	signal s_sel				: std_logic := '0';
	signal s_ss					: std_logic := '0';
	signal s_sload_n			: std_logic := '1';
	signal s_sl1_n				: std_logic := '1';
	signal s_sl2_n				: std_logic := '1';

	signal s_1H					: std_logic := '0';
	signal s_2H					: std_logic := '0';
	signal s_4H					: std_logic := '0';
	signal s_8H					: std_logic := '0';
	signal s_16H				: std_logic := '0';
	signal s_32H				: std_logic := '0';
	signal s_64H				: std_logic := '0';
	signal s_128H				: std_logic := '0';
	signal s_256H_n			: std_logic := '1';

	signal s_8H_x				: std_logic := '0';
	signal s_16H_x				: std_logic := '0';
	signal s_32H_x				: std_logic := '0';
	signal s_64H_x				: std_logic := '0';
	signal s_128H_x			: std_logic := '0';

	signal s_1V_x				: std_logic := '0';
	signal s_2V_x				: std_logic := '0';
	signal s_4V_x				: std_logic := '0';
	signal s_8V_x				: std_logic := '0';
	signal s_16V_x				: std_logic := '0';
	signal s_32V_x				: std_logic := '0';
	signal s_64V_x				: std_logic := '0';
	signal s_128V_x			: std_logic := '0';
	signal s_vsync_n			: std_logic := '1';

	signal s_1V_r				: std_logic := '0';
	signal s_1V_n_r			: std_logic := '1';
	signal s_256H_r			: std_logic := '0';
	signal s_contrlda_n		: std_logic := '1';
	signal s_contrldb_n		: std_logic := '1';
	
	-- HISCORE
	signal hs_enable_1e		: std_logic := '0';
	signal hs_enable_6lm		: std_logic := '0';
	signal hs_data_out_1e	: std_logic_vector(7 downto 0) := (others => '0');
	signal hs_data_out_6lm	: std_logic_vector(7 downto 0) := (others => '0');
	
	-- CONSTANTS
	signal one		        : std_logic := '1';

begin

	O_VIDEO_R			<= s_red;
	O_VIDEO_G			<= s_grn;
	O_VIDEO_B			<= s_blu;
	O_HSYNC				<= s_hsync_n;
	O_VSYNC				<= s_vsync_n;
	O_CMPBLK_n			<= s_cmpblk_n_r;

	clk_4M_en			<= I_CLK_4M;
	clk_6M_en			<= I_CLK_6M;
	clk_12M				<= I_CLK_12M;

	RESETn				<= not I_RESET;		-- active low reset

	O_HBLANK <= s_256H_r;


	-- HISCORE MUX
	hs_enable_1e	<= '1' when (hs_address(15 downto 11) = "10000"   ) else '0'; -- 0x8000 - 0x87ff
	hs_enable_6lm	<= '1' when (hs_address(15 downto 11) = "10010"   ) else '0'; -- 0x9000 - 0x97ff
	hs_data_out 	<=	hs_data_out_1e when hs_enable_1e = '1' else hs_data_out_6lm;
	
	----------------------------------------------------------------------------
	-- concatenate some signals so we can pass them to modules as a logic vector
	----------------------------------------------------------------------------
	s_6p_bus		<= s_4V_x & s_2V_x & s_1V_x;
	s_t_bus		<= s_4V_x & s_2V_x & s_1V_x & s_8V_x & s_8H_x;
	s_4p_bus		<= s_4H & s_128V_x & s_64V_x & s_32V_x & s_16V_x & s_128H_x & s_64H_x & s_32H_x & s_16H_x;
	s_5ef_bus	<= s_128V_x & s_64V_x & s_32V_x & s_16V_x & s_8V_x & s_4V_x & s_2V_x & s_1V_x;
	s_6lm_bus	<= s_2H & s_128V_x & s_64V_x & s_32V_x & s_16V_x & s_8V_x & s_128H_x & s_64H_x & s_32H_x & s_16H_x & s_8H_x;

	-------------------------------------------------------------------------------------------------------------
	-- CPU data bus mux: depending on address decoding logic connects a specific source to the cpu data bus input
	-------------------------------------------------------------------------------------------------------------
	cpu_data_in <=
		ram0_data		when							  (s_ram0_n = '0')		else -- chips 2H, 6N8 page 1
		ram1_data		when							  (s_ram1_n = '0')		else -- chips 2H, 6N8 page 1
		rom_data			when (s_merd_n = '0') and (rom_sel /= "11111")	else -- chips 2H, 6N8 page 1
		char_data		when (s_merd_n = '0') and (s_cs_9000_n = '0')	else -- chips 3L, 2R6, 8C6, 6N11 page 6
		sprite_data		when (s_merd_n = '0') and (s_cs_9800_n = '0')	else -- chips 2F, 7C8, 3H6 page 4
		palette_data	when (s_merd_n = '0') and (s_cs_9c00_n = '0')	else -- chips 7B, 7C, 8C11, 8C8 page 8
		io_data			when (s_merd_n = '0') and (s_cs_b000_n = '0')	else -- chips 3N3, 3N11, 3P page 2
		(others => '0');

	-- chip 4L6 page 1
	cpu_reset_n <= RESETn and (not wd_ctr(3));

	-- chip 5N page 1
	watchdog : process(clk_12M, s_wdclr, I_PAUSE)
	begin
		if (s_wdclr = '1' or I_PAUSE = '1') then
			wd_ctr <= "0000";
		elsif falling_edge(clk_12M) then
			s_vblank_t1 <= s_vblank_t0;
			-- falling edge of s_vblank_n
			if (s_vblank_t0 = '0' and s_vblank_t1 = '1') then
				wd_ctr <= wd_ctr  + 1;
			end if;
		end if;
	end process;

	-- chip 3H3 page 1
	s_merd_n <= cpu_mreq_n or cpu_rd_n;

	-- chip 3H11 page 1
	s_mewr_n <= cpu_mreq_n or cpu_wr_n;

	-- chip 1C12 page 1
	process
	begin
		wait until rising_edge(clk_12M);
		-- only let this change when CPU not enabled
		if (clk_4M_en = '0') then
			s_wait <= not (s_ram2_n or s_sw_n or s_hbl);
		end if;
	end process;

	-- chip 4L3 page 1
	s_csen_n <= s_wait and s_7P5;

	-- chip 6P10 page 1 (deviation from schematic to cleanup the wait pulse by taking s_7P5 into account as well)
	-- added user/hiscore system controlled pause
	s_wait_n <= (not (s_wait or s_7P9 or s_7P5)) and (not I_PAUSE);

	-- clock enable for sound sections P9, P10
	s_clk_en <= s_1H and not clk_6M_en; -- create a 3M clock enable for the 12M clock

	-- chip 5P5 page 1
	U5P5 : process(clk_12M, s_nmion)
	begin
		if s_nmion = '0' then
			s_nmi_n <= '1';
		elsif falling_edge(clk_12M) then
			-- rising edge of s_vblank_n
			if (s_vblank_t0 = '1' and s_vblank_t1 = '0') then
				s_nmi_n <= '0';
			end if;
		end if;
	end process;

	-- chip 7P page 1
	U7P5 : process(clk_12M, s_vblank_t0)
	begin
		if s_vblank_t0 = '1' then
			s_7P5 <= '0';
		elsif rising_edge(clk_12M) then
			if (clk_4M_en = '1') then
				s_7P5 <= s_wait;
			end if;
		end if;
	end process;

	U7P9 : process
	begin
		wait until rising_edge(clk_12M);
		if (clk_4M_en = '1') then
			s_7P9 <= s_7P5;
		end if;
	end process;

	-- chips 1J, 1L, 1M, 1N, 1R page 1
	prog_roms : entity work.PROG_ROMS
	port map (
		clk_48M     => clk_48M,
		dn_addr     => dn_addr,
		dn_data     => dn_data,
		dn_wr       => dn_wr,

		I_CLK		   => clk_12M,
		I_ROM_SEL	=> rom_sel,
		I_ADDR		=> cpu_addr(12 downto 0),
		O_DATA		=> rom_data
	);

	-----------
	-- CPU RAMs
	-----------
	-- our BRAM signals are opposite polarity from real SRAMs
	s_wram0  <= not s_wram0_n;
	s_wram1  <= not s_wram1_n;
	s_mewr <= not s_mewr_n;
	
	-- CPU RAM 0x8000 - 0x87ff
	-- chip 1E page 1
	ram_1E : entity work.ram_1e
	port map (
		address_a	=> cpu_addr(10 downto 0),
		clock_a		=> clk_12M,
		enable_a	=> s_wram0,
		data_a		=> cpu_data_out,
		wren_a		=> s_mewr,
		q_a		=> ram0_data,
		-- HISCORE ACCESS
		address_b	=> hs_address(10 downto 0),
		clock_b		=> clk_48M,
		enable_b	=> hs_enable_1e,
		data_b		=> hs_data_in,
		wren_b		=> hs_write and hs_enable_1e,
		q_b		=> hs_data_out_1e
		
	);

	-- CPU RAM 0x8800 - 0x8fff
	-- chip 1H page 1
	ram_1H : entity work.ram_1h
	port map (
		address		=> cpu_addr(10 downto 0),
		clock		=> clk_12M,
		clken		=> s_wram1,
		data		=> cpu_data_out,
		wren		=> s_mewr,
		q		=> ram1_data
	);

	--------------------------------------------------------------------------------
	-- memory decoder generates active low select signals for various memory regions
	--------------------------------------------------------------------------------
	-- chip 3M page 1
	rom_sel(0)	<= '0' when (                      cpu_addr(15 downto 13) = "000"   ) else '1'; -- 0x0000 - 0x1fff
	rom_sel(1)	<= '0' when (                      cpu_addr(15 downto 13) = "001"   ) else '1'; -- 0x2000 - 0x3fff
	rom_sel(2)	<= '0' when (                      cpu_addr(15 downto 13) = "010"   ) else '1'; -- 0x4000 - 0x5fff
	rom_sel(3)	<= '0' when (                      cpu_addr(15 downto 13) = "011"   ) else '1'; -- 0x6000 - 0x7fff
	rom_sel(4)	<= '0' when ( cpu_mreq_n = '0' and cpu_addr(15 downto 13) = "110"   ) else '1'; -- 0xc000 - 0xdfff

	-- chip 5M page 1
	s_ram0_n		<= '0' when ( cpu_mreq_n = '0' and cpu_addr(15 downto 11) = "10000" ) else '1'; -- 0x8000 - 0x87ff
	s_ram1_n		<= '0' when ( cpu_mreq_n = '0' and cpu_addr(15 downto 11) = "10001" ) else '1'; -- 0x8800 - 0x8fff
	s_ram2_n		<= '0' when ( cpu_mreq_n = '0' and cpu_addr(15 downto 11) = "10010" ) else '1'; -- 0x9000 - 0x97ff

	-- chip 4M page 1
	s_wram0_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 11) = "10000"  ) else '1'; -- 0x8000 - 0x87ff
	s_wram1_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 11) = "10001"  ) else '1'; -- 0x8800 - 0x8fff
	s_cs_9000_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 11) = "10010"  ) else '1'; -- 0x9000 - 0x97ff
	s_cs_b000_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 11) = "10110"  ) else '1'; -- 0xb000 - 0xb7ff
	s_cs_b800_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 11) = "10111"  ) else '1'; -- 0xb800 - 0xbfff

	-- chip 2S page 1
	s_cs_9800_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 9) = "1001100" ) else '1'; -- 0x9800 - 0x99ff
	s_cs_9a00_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 9) = "1001101" ) else '1'; -- 0x9a00 - 0x9bff
	s_cs_9c00_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 9) = "1001110" ) else '1'; -- 0x9c00 - 0x9dff
	s_cs_9e00_n	<= '0' when ( cpu_mreq_n = '0' and cpu_rfsh_n = '1' and s_csen_n = '0' and cpu_addr(15 downto 9) = "1001111" ) else '1'; -- 0x9e00 - 0x9fff

	------------------------
	-- Z80 CPU on main board
	------------------------
	-- chip 3K page 1
	cpu_3K : entity work.T80sed
	port map (
		-- inputs
		WAIT_n		=> s_wait_n,
		NMI_n		=> s_nmi_n,
		DI		=> cpu_data_in,
		RESET_n		=> cpu_reset_n,
		CLK_n		=> clk_12M,
		CLKEN		=> clk_4M_en,
		INT_n		=> one,  -- unused
		BUSRQ_n		=> one,  -- unused
		-- outputs
		RFSH_n		=> cpu_rfsh_n,
		MREQ_n		=> cpu_mreq_n,
		RD_n		=> cpu_rd_n,
		WR_n		=> cpu_wr_n,
		A		=> cpu_addr,
		DO		=> cpu_data_out,
		M1_n		=> open, -- unused
		IORQ_n		=> open, -- unused
		HALT_n		=> open, -- unused
		BUSAK_n		=> open  -- unused
	);

	s_flip_switched <= flip_screen xor s_flip;
	-------------------------------------------------------------------------
	-- page 2 schematic - input switches, watchdog and non-maskable interrupt
	-------------------------------------------------------------------------
	p2 : entity work.switches
	port map (
		I_CLK_12M	=> clk_12M,
		I_CLK_6M_EN	=> clk_6M_en,
		I_AB		=> cpu_addr(2 downto 0),
		I_DB0		=> cpu_data_out(0),
		I_CS_B000_n	=> s_cs_b000_n,		-- mem select region 0xb000 - 0xb7ff
		I_MERD_n	=> s_merd_n,		-- mem rd signal
		I_MEWR_n	=> s_mewr_n,		-- mem wr signal
		--
		I_P1		=> I_P1,		-- Player 1 active low switches
		I_P2		=> I_P2,		-- Player 2 active low switches
		I_SYS		=> I_SYS,		-- System active low switches
		I_SW1		=> I_SW1,		-- SW1 presets
		I_SW2		=> I_SW2,		-- SW2 presets
		--
		O_DB		=> io_data,
		O_WDCLR		=> s_wdclr,
		O_NMION		=> s_nmion,
		O_FLIP 		=> s_flip,
		flip_screen	=> flip_screen
	);


	-------------------------------------------------------
	-- page 3 schematic - video and timing signal generator
	-------------------------------------------------------
	p3 : entity work.timing
	port map (
		I_CLK_12M	=> clk_12M,
		I_CLK_6M_EN	=> clk_6M_en,
		I_FLIP		=> s_flip_switched,
		I_CS_9A00_n	=> s_cs_9a00_n,
		I_MEWR_n				=> s_mewr_n,
		I_AB					=> cpu_addr(0),
		I_DB					=> cpu_data_out( 3 downto 0),
		--
		O_SLOAD_n			=> s_sload_n,
		O_SL1_n				=> s_sl1_n,
		O_SL2_n				=> s_sl2_n,
		O_SW_n				=> s_sw_n,
		O_SS					=> s_ss,
		O_HBL					=> s_hbl,
		O_CONTROLDB_n		=> s_contrldb_n,
		O_CONTROLDA_n		=> s_contrlda_n,
		O_VPL_n				=> s_vpl_n,
		O_CDL_n				=> s_cdl_n,
		O_MDL_n				=> s_mdl_n,
		O_SEL					=> s_sel,
		O_1V_r				=> s_1V_r,
		O_1V_n_r				=> s_1V_n_r,
		O_256H_r				=> s_256H_r,
		O_CMPBLK_n_r		=> s_cmpblk_n_r,
		O_CMPBLK_n			=> s_cmpblk_n,
--		O_CMPBLK				=> open,
		O_VBLANK_n			=> s_vblank_n,
		O_VBLANK				=> s_vblank_t0,
		O_VBLANK_r        => O_VBLANK,
		O_TVSYNC_n			=> open,
		O_HSYNC_n 			=> s_hsync_n,

		O_1H					=> s_1H,
		O_2H					=> s_2H,
		O_4H					=> s_4H,
		O_8H					=> s_8H,
		O_16H					=> s_16H,
		O_32H					=> s_32H,
		O_64H					=> s_64H,
		O_128H				=> s_128H,
		O_256H_n 			=> s_256H_n,

		O_8H_X				=> s_8H_x,
		O_16H_X				=> s_16H_x,
		O_32H_X				=> s_32H_x,
		O_64H_X				=> s_64H_x,
		O_128H_X 			=> s_128H_x,

		O_1V_X				=> s_1V_x,
		O_2V_X				=> s_2V_x,
		O_4V_X				=> s_4V_x,
		O_8V_X				=> s_8V_x,
		O_16V_X				=> s_16V_x,
		O_32V_X				=> s_32V_x,
		O_64V_X				=> s_64V_x,
		O_128V_X				=> s_128V_x,
		O_VSYNC_n			=> s_vsync_n
	);

	--------------------------------------
	-- page 4 schematic - sprite generator
	--------------------------------------
	p4 : entity work.sprite_gen
	port map (
		I_CLK_6M_EN			=> clk_6M_en,
		I_CLK_12M			=> clk_12M,
		I_CS_9800_n			=> s_cs_9800_n,
		I_MEWR_n				=> s_mewr_n,
		I_MDL_n				=> s_mdl_n,
		I_CDL_n				=> s_cdl_n,
		I_VPL_n				=> s_vpl_n,
		I_SLOAD_n			=> s_sload_n,
		I_SEL					=> s_sel,

		I_2H					=> s_2H,
		I_4H					=> s_4H,
		I_8H					=> s_8H,
		I_16H					=> s_16H,
		I_32H					=> s_32H,
		I_64H					=> s_64H,
		I_128H				=> s_128H,
		I_256H_n				=> s_256H_n,

		I_5EF_BUS			=> s_5ef_bus,
		I_AB					=> cpu_addr( 6 downto 0),
		I_DB					=> cpu_data_out,
		I_ROM_7JLM_DATA	=> I_ROM_7JLM_DATA,
		--
		O_ROM_7JLM_ENA		=> O_ROM_7JLM_ENA,
		O_ROM_7JLM_ADDR	=> O_ROM_7JLM_ADDR,
		O_MHFLIP				=> s_mhflip,
		O_MC					=> s_mc,
		O_MV					=> s_mv,
		O_DB					=> sprite_data
	);

	----------------------------------------
	-- page 5 schematic - sprite positioning
	----------------------------------------
	p5 : entity work.sprite_position
	port map (
		I_CLK_12M		=> clk_12M,
		I_CLK_6M_EN		=> clk_6M_en,
		I_FLIP			=> s_flip_switched,
		I_CONTRLDA_n	=> s_contrlda_n,
		I_CONTRLDB_n	=> s_contrldb_n,
		I_MHFLIP			=> s_mhflip,
		I_1V_r			=> s_1V_r,
		I_1V_n_r			=> s_1V_n_r,
		I_256H_r			=> s_256H_r,
		I_CTR				=> sprite_data,
		I_MC				=> s_mc,
		I_MV				=> s_mv,
		--
		O_OC				=> s_oc,
		O_OV				=> s_ov
	);

	-----------------------------------------
	-- page 6 schematic - character generator
	-----------------------------------------
	p6 : entity work.char_gen
	port map (
		I_CLK_12M			=> clk_12M,
		I_CLK_6M_EN			=> clk_6M_en,
		I_CS_9000_n			=> s_cs_9000_n,
		I_MEWR_n				=> s_mewr_n,
		I_CMPBLK_n			=> s_cmpblk_n,
		I_FLIP				=> s_flip_switched,
		I_SS					=> s_ss,
		I_SL1_n				=> s_sl1_n,
		I_SL2_n				=> s_sl2_n,
		I_SLOAD_n			=> s_sload_n,
		I_6LM_BUS			=> s_6lm_bus,
		I_DB					=> cpu_data_out,
		I_AB					=> cpu_addr(10 downto 0),
		I_ROM_8KHE_DATA	=> I_ROM_8KHE_DATA,
		I_6P_BUS				=> s_6p_bus,
		--
		O_SV					=> s_sv,
		O_SC					=> s_sc,
		O_DB					=> char_data,
		O_ROM_8KHE_ENA		=> O_ROM_8KHE_ENA,
		O_ROM_8KHE_ADDR	=> O_ROM_8KHE_ADDR,
		
		-- HISCORE
		I_CLK_48M			=>	clk_48M,
		hs_address			=> hs_address,
		hs_data_out			=> hs_data_out_6lm,
		hs_data_in			=> hs_data_in,
		hs_write				=> (hs_write and hs_enable_6lm),
		hs_enable			=> hs_enable_6lm
	);

	------------------------------------------------
	-- page 7 schematic - background image generator
	------------------------------------------------
	p7 : entity work.bgnd_tiles
	port map (
		I_CLK_12M			=> clk_12M,
		I_CLK_6M_EN			=> clk_6M_en,
		I_CS_9E00_n			=> s_cs_9e00_n,
		I_MEWR_n				=> s_mewr_n,
		I_CMPBLK_n			=> s_cmpblk_n,
		I_SLOAD_n			=> s_sload_n,
		I_SL2_n				=> s_sl2_n,
		I_FLIP				=> s_flip_switched,
		I_4P_BUS				=> s_4p_bus,
		I_T_BUS				=> s_t_bus,
		I_DB					=> cpu_data_out(4 downto 0),
		I_ROM_4P_DATA		=> I_ROM_4P_DATA,
		I_ROM_8RNL_DATA	=> I_ROM_8RNL_DATA,
		--
		O_ROM_4P_ENA		=> O_ROM_4P_ENA,
		O_ROM_4P_ADDR		=> O_ROM_4P_ADDR,
		O_ROM_8RNL_ENA		=> O_ROM_8RNL_ENA,
		O_ROM_8RNL_ADDR	=> O_ROM_8RNL_ADDR,
		O_BC					=> s_bc,
		O_BV					=> s_bv
	);

	----------------------------------------------------
	-- page 8 schematic - color palette and video output
	----------------------------------------------------
	p8 : entity work.palette
	port map (
		I_CLK_12M			=> clk_12M,
		I_CLK_6M_EN			=> clk_6M_en,
		I_CS_9C00_n			=> s_cs_9c00_n,
		I_MEWR_n				=> s_mewr_n,
		I_MERD_n				=> s_merd_n,
		I_CMPBLK_n_r		=> s_cmpblk_n_r,
		I_VBLANK_n			=> s_vblank_n,
		I_OC					=> s_oc,
		I_OV					=> s_ov,
		I_SC					=> s_sc,
		I_SV					=> s_sv,
		I_BC					=> s_bc,
		I_BV					=> s_bv,
		I_AB					=> cpu_addr(8 downto 0),
		I_DB					=> cpu_data_out,
		--
		O_DB					=> palette_data,
		O_R					=> s_red,
		O_G					=> s_grn,
		O_B					=> s_blu
	);

	-----------------------------------------
	-- page 9 schematic - audio CPU, ROM, RAM
	-----------------------------------------
	p9 : entity work.audio
	port map (
		clk_48M           => clk_48M,
		dn_addr           => dn_addr,
		dn_data           => dn_data,
		dn_wr             => dn_wr,

		I_CLK_12M			=> clk_12M,
		I_CLK_EN				=> s_clk_en,
		I_RESET_n			=> RESETn,
		I_VSYNC_n			=> s_vsync_n,
		I_CS_B800_n			=> s_cs_b800_n,
		I_MERW_n				=> s_mewr_n,
		I_DB_CPU				=> cpu_data_out,
		I_SD					=> psg_data_out,
		O_SD					=> psg_data_in,
		O_SA0					=> s_sa0,
		O_PSG1_n				=> s_psg1_n,
		O_PSG2_n				=> s_psg2_n,
		O_PSG3_n				=> s_psg3_n,
		O_SWR_n				=> s_swr_n,
		O_SRD_n				=> s_srd_n
	);

	----------------------------------------------------
	-- page 10 schematic - programmable sound generators
	----------------------------------------------------
	p10 : entity work.psgs
	port map (
		I_CLK_12M			=> clk_12M,
		I_CLK_EN				=> s_clk_en,
		I_RST_n				=> RESETn,
		I_SWR_n				=> s_swr_n,
		I_SRD_n				=> s_srd_n,
		I_SA0					=> s_sa0,
		I_PSG1_n				=> s_psg1_n,
		I_PSG2_n				=> s_psg2_n,
		I_PSG3_n				=> s_psg3_n,
		I_CHEN				=> "111111111",
		I_SD					=> psg_data_in,
		O_SD					=> psg_data_out,
		O_AUDIO				=> O_AUDIO
	);

end RTL;
