--
-- VoiceRom.vhd
--
-- Copyright (c) 2006 Mitsutaka Okazaki (brezza@pokipoki.org)
-- All rights reserved.
--
-- Redistribution and use of this source code or any derivative works, are
-- permitted provided that the following conditions are met:
--
-- 1. Redistributions of source code must retain the above copyright notice,
--    this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 3. Redistributions may not be sold, nor may they be used in a commercial
--    product or activity without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
-- "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
-- CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
-- EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
-- PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
-- WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
-- OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
--
-- based on bumbed voices:  https://siliconpr0n.org/archive/doku.php?id=vendor:yamaha:opl2

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use WORK.VM2413.ALL;

entity VoiceRom is
  generic (VRC7 : std_logic := '0');
  port (
    clk    : in std_logic;
    addr : in VOICE_ID_TYPE;
    data  : out VOICE_TYPE
  );
end VoiceRom;

architecture RTL of VoiceRom is

  type VOICE_ARRAY_TYPE is array (0 to 37) of std_logic_vector(35 downto 0);
 
  constant base_voices : VOICE_ARRAY_TYPE := (
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000000000000000000000000000000000", -- @0(M)
    "000000000000000000000000000000000000", -- @0(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011100010001111001111101000000000000", -- @1(M)
    "011000010000000010000111100000010111", -- @1(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000100110001101011011101100000100011", -- @2(M)
    "010000010000000000001111011100010011", -- @2(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000100111001100100001111001000010001", -- @3(M)
    "000000010000000000001100010000100011", -- @3(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001100010000111001111010100001110000", -- @4(M)
    "011000010000000000000110010000100111", -- @4(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001100100001111001101110000000000000", -- @5(M)
    "001000010000000000000111011000101000", -- @5(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001100010001011001011110000000000000", -- @6(M)
    "001000100000000000000111000100011000", -- @6(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001000010001110101111000001000010000", -- @7(M)
    "011000010000000000001000000100000111", -- @7(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001000110010110101001010001000000000", -- @8(M)
    "001000010000000010000111001000000111", -- @8(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011000010001101101100110010000010000", -- @9(M)
    "011000010000000000000110010100010111", -- @9(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "010000010000101110001000010101110001", -- @10(M)
    "011000010000000010001111011100000111", -- @10(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000100111000001100011111101000010000", -- @11(M)
    "000000010000000010001110010000000100", -- @11(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000101110010010001111111100000100010", -- @12(M)
    "110000010000000000001111100000010010", -- @12(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011000010000110001011100001000100000", -- @13(M)
    "010100000000000000001111010101000010", -- @13(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000010101010100111100100100000011", -- @14(M)
    "000000010000000000001001010100000010", -- @14(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011000011000100100111111000101000000", -- @15(M)
    "010000010000000000001110010000010011", -- @15(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000010001100011111101111101101010", -- BD(M)
    "000000010000000000001111100001101101", -- BD(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000010000000000001100100010100111", -- HH
    "000000010000000000001101100001001000", -- SD
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000001010000000000001111100001011001", -- TOM
    "000000010000000000001010101001010101"  -- CYM
  );

  --Register  Bitfield   Description
  --$00       TVSK MMMM  Modulator tremolo (T), vibrato (V), sustain (S), key rate scaling (K), multiplier (M)
  --$01       TVSK MMMM  Carrier tremolo (T), vibrato (V), sustain (S), key rate scaling (K), multiplier (M)
  --$02       KKOO OOOO  Modulator key level scaling (K), output level (O)
  --$03       KK-Q WFFF  Carrier key level scaling (K), unused (-), carrier waveform (Q), modulator waveform (W), feedback (F)
  --$04       AAAA DDDD  Modulator attack (A), decay (D)
  --$05       AAAA DDDD  Carrier attack (A), decay (D)
  --$06       SSSS RRRR  Modulator sustain (S), release (R)
  --$07       SSSS RRRR  Carrier sustain (S), release (R)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>

  constant vrc7_voices : VOICE_ARRAY_TYPE := (
    "000000000000000000000000000000000000", -- @0(M)
    "000000000000000000000000000000000000", -- @0(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000110000010101101110100001000010", -- @1(M)
    "001000010000000000001000000100100111", -- @1(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000100110001010011011101100000100011", -- @2(M)
    "010000010000000000001111011000010010", -- @2(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000100010000100010001111101000100000", -- @3(M)
    "000100010000000000001011001000010010", -- @3(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001100010000110001111010100001100001", -- @4(M)
    "011000010000000000000110010000100111", -- @4(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001100100001111001101110000100000001", -- @5(M)
    "001000010000000000000111011000101000", -- @5(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000100000011000001010001111110100", -- @6(M)
    "000000010000000000001110001011110100", -- @6(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001000010001110101111000001000010001", -- @7(M)
    "011000010000000000001000000100000111", -- @7(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001000110010001001111010001000000001", -- @8(M)
    "001000010000000010000111001000010111", -- @8(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001101010010010100000100000001110010", -- @9(M)
    "000100010000000000000111001100000001", -- @9(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "101101010000111111111010100001010001", -- @10(M)
    "000000010000000000001010010100000010", -- @10(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000101110010010001111111100000100010", -- @11(M)
    "110000010000000000001111100000010010", -- @11(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011100010001000101100110010100011000", -- @12(M)
    "001000110000000000000111010000010110", -- @12(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000011101001101011100100100000011", -- @13(M)
    "000000100000000000001001010100000010", -- @13(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "011000010000110000001001010000110011", -- @14(M)
    "011000110000000000001100000011110110", -- @14(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "001000010000110100001100000101010110", -- @15(M)
    "011100100000000000001101010100000110", -- @15(C)
    -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000010001100011111101111101101010", -- BD(M)
    "000000010000000000001111100001101101", -- BD(C)
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000000010000000000001100100010100111", -- HH
    "000000010000000000001101100001001000", -- SD
  -- APEK<ML>KL< TL >W<F><AR><DR><SL><RR>
    "000001010000000000001111100001011001", -- TOM
    "000000010000000000001010101001010101"  -- CYM
  );

begin

  process (clk)

  begin

    if rising_edge(clk) then
      if (VRC7 = '0') then
        data <= CONV_VOICE(base_voices(addr));
      else
        data <= CONV_VOICE(vrc7_voices(addr));
      end if;
    end if;

  end process;

end RTL;