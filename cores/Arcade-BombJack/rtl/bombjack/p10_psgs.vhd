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
-- Each analog sound output is fed through a programmable inverting
-- amplifier implemented with 4066 switches and LM324 op-amps
--
-- There are three resistors, 68K (always connected) then 47K and 22K
-- which can be independently switched on in parallel with the 68K
--
-- The total resistance (Rt) of these determines the amplification of
-- the op-amp based on its 22K feedback resistor Rf as: Vout = -Vin * (Rf/Rt)
--
-- Two digital output lines per analog channel control the amplification factor as:
-- IOA_hi IOA_lo Resistance        Total resistance  Amplification
--    0      0   68K                     68K            x0.3
--    0      1   68K || 47K              27.8K          x0.8
--    1      0   68K || 22K              16.6K          x1.3
--    1      1   68K || 47K || 22K       12.3K          x1.8
--------------------------------------------------------------------------------

-- ###########################################################################
-- ##### PAGE 10 schema - programmable sound generators                  #####
-- ###########################################################################

library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;
	use ieee.std_logic_arith.all;

entity psgs is
	port (
		I_CLK_12M	: in  std_logic;
		I_CLK_EN		: in  std_logic;
		I_RST_n		: in  std_logic;
		I_SWR_n		: in  std_logic;
		I_SRD_n		: in  std_logic;
		I_SA0			: in  std_logic;
		I_PSG1_n		: in  std_logic;
		I_PSG2_n		: in  std_logic;
		I_PSG3_n		: in  std_logic;
		I_CHEN		: in  std_logic_vector( 8 downto 0);
		I_SD			: in  std_logic_vector (7 downto 0);
		O_SD			: out std_logic_vector (7 downto 0);
		O_AUDIO		: out std_logic_vector (7 downto 0)
	);
end psgs;

architecture RTL of psgs is
	signal s_5C4			: std_logic := '0';
	signal s_5A1			: std_logic := '0';
	signal s_5A10			: std_logic := '0';
	signal s_5A13			: std_logic := '0';
	signal s_5B1			: std_logic := '0';
	signal s_5B10			: std_logic := '0';
	signal s_5B13			: std_logic := '0';
	signal s_5C1			: std_logic := '0';
	signal s_5C10			: std_logic := '0';
	signal s_5C13			: std_logic := '0';
	signal s_dac_out		: std_logic := '0';
	signal s_audio_sum	: std_logic_vector( 9 downto 0) := (others => '0');
	signal s_34A_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_34C_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_34D_data		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_psg1_out		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_psg2_out		: std_logic_vector( 7 downto 0) := (others => '0');
	signal s_psg3_out		: std_logic_vector( 7 downto 0) := (others => '0');

	signal zero		        : std_logic := '0';
	signal one		        : std_logic := '1';

begin
	-- CPU data bus mux
	O_SD <=
		s_34A_data	when (I_PSG3_n  = '0') else
		s_34C_data	when (I_PSG2_n  = '0') else
		s_34D_data	when (I_PSG1_n  = '0') else
		(others => '0');

	-- chips 5A, 5B, 5C page 10
	s_5C4  <= not I_SA0;
	s_5A1  <= I_PSG3_n nor I_SWR_n;
	s_5A13 <= I_PSG3_n nor I_SRD_n;
	s_5A10 <= I_PSG3_n nor s_5C4;
	s_5B1  <= I_PSG2_n nor I_SWR_n;
	s_5B13 <= I_PSG2_n nor I_SRD_n;
	s_5B10 <= I_PSG2_n nor s_5C4;
	s_5C1  <= I_PSG1_n nor I_SWR_n;
	s_5C13 <= I_PSG1_n nor I_SRD_n;
	s_5C10 <= I_PSG1_n nor s_5C4;

	U34D : entity work.ym2149
		port map (
			CLK						=> I_CLK_12M,
			ENA						=> I_CLK_EN,
			RESET_L					=> I_RST_n,
			-- data bus
			I_DA						=> I_SD,
			O_DA						=> s_34D_data,
			-- control
			I_A9_L					    => zero,
			I_A8						=> one,
			I_SEL_L					    => zero, -- low to halve the 3Mhz clock

			I_BDIR					=> s_5C1,
			I_BC2						=> s_5C10,
			I_BC1						=> s_5C13,

			I_CHEN					=> I_CHEN(8 downto 6),
			O_AUDIO					=> s_psg1_out
		);

	U34C : entity work.ym2149
		port map (
			CLK						=> I_CLK_12M,
			ENA						=> I_CLK_EN,
			RESET_L					=> I_RST_n,
			-- data bus
			I_DA						=> I_SD,
			O_DA						=> s_34C_data,
			-- control
			I_A9_L					=> zero,
			I_A8					=> one,
			I_SEL_L					=> zero, -- low to halve the 3Mhz clock

			I_BDIR					=> s_5B1,
			I_BC2						=> s_5B10,
			I_BC1						=> s_5B13,

			I_CHEN					=> I_CHEN(5 downto 3),
			O_AUDIO					=> s_psg2_out
		);

	U34A : entity work.ym2149
		port map (
			CLK						=> I_CLK_12M,
			ENA						=> I_CLK_EN,
			RESET_L					=> I_RST_n,
			-- data bus
			I_DA						=> I_SD,
			O_DA						=> s_34A_data,
			-- control
			I_A9_L					=> zero,
			I_A8					=> one,
			I_SEL_L					=> zero, -- low to halve the 3Mhz clock

			I_BDIR					=> s_5A1,
			I_BC2						=> s_5A10,
			I_BC1						=> s_5A13,

			I_CHEN					=> I_CHEN(2 downto 0),
			O_AUDIO					=> s_psg3_out
		);

	s_audio_sum <=
		(("00" & s_psg1_out) + ("00" & s_psg2_out)) + ("00" & s_psg3_out);

	O_AUDIO	<= s_audio_sum(9 downto 2);


end RTL;

