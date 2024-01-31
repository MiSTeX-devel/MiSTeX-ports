---------------------------------------------------------------------------------
-- Popeye by Dar (darfpga@aol.fr) (26/12/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
--
-- release rev 04 : MiSTer configuration
--  (01/03/2020)
--
-- release rev 03 : no change but hardware description
--  (27/01/2020)
--
-- release rev 02 : clean MNI disable/enable, add hardware description
--  (25/01/2020)
--
-- release rev 01 : added protection algorithm (straight forward from MAME)
--  (01/01/2020)  : tested ok for Popeye rev D level 1 at least...
--
-- release rev 00 : initial release
--  (26/12/2019)
--
---------------------------------------------------------------------------------
-- gen_ram.vhd & io_ps2_keyboard
-------------------------------- 
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
---------------------------------------------------------------------------------
-- T80/T80se - Version : 304
-----------------------------
-- Z80 compatible microprocessor core
-- Copyright (c) 2001-2002 Daniel Wallner (jesus@opencores.org)
---------------------------------------------------------------------------------
-- YM2149 (AY-3-8910)
-- Copyright (c) MikeJ - Jan 2005
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
--  Features :
--   Video        : VGA 31kHz/60Hz progressive and TV 15kHz interlaced
--   Coctail mode : NO
--   Sound        : OK
--
--  Use with MAME roms from popeye.zip & popeyeu.zip
--
--  Use make_popeye_proms.bat to build vhd file from binaries
--  (CRC list included)
--
---------------------------------------------------------------------------------
--  Popeye Hardware caracteristics from schematics TPP2:
--
--  2 digits numbers such as '(8P)' refers to TPP2 schematics. I miss to mention
--  which board it refers to (cpu or video). I hope it will not be too much
--  misleading, Take care !  
--
--		Video  quartz	is 20.16MHz.
--
--	   Display is 512x448 pixels (video 640 pixels x 256 interlaced lines @ 10.08MHz).
--
--    Original interlaced timings :
--      640/10.08e6  = 63.49us per line  (15.750kHz).
--      63.49*256 = 16.254ms per frame (61.52Hz).
--
--    VHDL 60Hz Adapted interlaced timings (263 lines instead of 256):
--      640/10.08e6  = 63.49us per line  (15.750kHz).
--      63.49*263 = 16.70ms per frame (59.89Hz).
-- 
--    VHDL 60Hz Adapted progressive timings (526 lines instead of 512):
--      640/20.16e6  = 31.75us per line  (31.50kHz).
--      31.75*526 = 16.70ms per frame (59.89Hz).
--   
--    One char tile map 32x28 of 8x8 dots (1 char dot is 2 pixels x 2 lines).
--      1Kx8bits text ram (5P/5R).
--      1kx4bits color ram (5S).
--      4Kx8bits graphics rom 1bits/dot (5N):
--        addr = '1' + 8b code + 3b line (only 2K used).
--        data = 8 pixels x 1bit color.
--      32x8bits rom color palette (3A):
--        addr = 1bit duplicated + 4bits individual char (only 16 colors used).
--        data = 8bits => 3red 3green 2blue.
--
--    One backgroud bitmap 64x128 blocs of 4x2 dots (1 background dot is 2 pixels x 2 lines).
--     One bloc has a single color and is 8 pixels x 4 lines.
--     Low nibble of memory holds colors for the first 64x64 blocs => upper half screen.
--     High nibble of memory holds colors for the last 64x64 blocs => lower half screen.
--     Total playground is 512 pixels x 512 lines.

--	     4Kx8bits bitmap ram - addressed by cpu/video as 8Kx4bits - (8P/8S):
--        addr = 7bits #Y bloc position + 6bits #X bloc position.
--        data = 4bits individual bloc color.
--      1bit global background color (whole frame) comes from sprite buffer ram.
--      32x8bits rom color palette (4A):
--        addr = 1bit global + 4bits individual bloc.
--        data = 8bits => 3red 3green 2blue.
--
--    Sprites are 16 pixels x 16 lines objects (1 object dot is 1 pixels x 1 lines):
--      There are 512 different graphics (9bits code).
--      4x8Kx8bits graphics rom addressed as 8Kx32bits (1K/1J/1F/1E):
--        addr = 9bits code + 4bits line.
--        data = 16 pixels x 2bits color.
--      3bits object color comes from each individual sprite data.
--      3bits global object color (whole frame) comes from sprite buffer ram.
--      2x256x4bits rom color palette - addressed as 256x8bits - (5B/5A):
--        addr = 3bits global + 3bits individual object + 2bits graphics data.
--        data = 8bits => 3red 3green 2blue.
--
--      Sprites have 1x1 pixel/line resolution but sprite H/V position have 2x2
--      pixels/lines resolution
--
--    Program rom is 4x8Kx8bits addressed as 32Kx8bits (7A/7B/7C/7E):
--      addresses are bits swapped and xored w.r.t cpu addresses (6E/6F/6H).
--      data      are bits swapped w.r.t cpu data.
--
--    Working ram is 2Kx8bits (7H)
--      working ram is addressed by cpu and by sprite data dma.
--
--    Char machine is quite straight forward.
--    Cpu has always priority access to text and color ram over video scanner.
--    Cpu address bits are unswapped at address mux level (6P/6R/6S).
--    Cpu address bits may be unxored at PLA level (5U).
--
--    Background machine has X/Y scroll (shift) mechanism:
--      X (horizontal) scrolling uses a counter (7N/7M) which initial value is
--      loaded for each line from sprite buffer ram.
--      Y (vertical) scrolling uses a line adder (3S/3R) and a register (8N)
--      which value is loaded for each line from sprite buffer ram.
--
--    Background machine has 8bits/4bits mux/dmux mecanism:
--      cpu_addr(12) allow to select writing to low nibble or high nibble of 
--      background bitmap thru muxers (8T/7T/7U) and register (8U). high nibble
--      is written back unchanged when writing low nibble and vice-versa with low
--      and high nibbles.
--      MSB of scrolled line count is used to select low or high nibble to be
--      displayed.
--
--    Cpu has always priority access to background bitmap ram over video scanner.
--    Cpu address bits are unswapped at address mux level (7P/7R/7S).
--    Cpu address bits may be unxored at PLA level (5U).
--
--    Sprite mecanism is based on 4 main steps:
--      - Sprite data are first written/read by cpu to/from working ram (7H).
--
--      - Once per frame sprite data are transfered from working ram to sprite
--        buffer ram (2T/1T/2S/1S/2R/1R/2U/1U).
--
--      - Once per line sprite data are filtered and transfered to sprite line
--        buffer (1M/3M and 1P/3P).
--
--      - Once per line sprite line is read to immediatly feed sprite graphics
--        roms.
--
--    Cpu has always access to working ram except when address and data buses are
--    requested by BUSRQ signal.
--
--    Sprite data tranfer from working ram to sprite buffer ram:
--      On VBlank signal event cpu address and data buses are requested (1L) and 
--      sprite dma 11bits counter (1F/2F/2E) drives address bus directly to sprite
--      buffer ram address and thru PLA (3E/4E) to working ram address. Data bus
--      is then driven by working ram data to feed sprite buffer ram data.
--      Bits 8 and 9 of dma counter are used to demux sprite buffer ram CS while
--      they are used to feed bits 0 and 1 of working ram address.
--      
--      So 8bits data from working ram address range x000-x3FF are transfered to 
--      32bits data of sprite buffer ram address range x00-xFF. 4 consecutives
--      bytes from working ram feed 1 dword of sprite buffer ram.
-- 
--      Except for address 0, each dword of sprite buffer ram holds 1 sprite data
--      (X pos, Y pos, code, color, attributs). From that point of view there 
--      could be 255 sprites to be displayed (see below).
--
--      Address 0 of sprite buffer ram contains background data (X scroll,
--      Y scroll, global color) and sprite data (global color).
--      In VHDL code these data are not taken from sprite buffer ram but latched
--      directly when cpu writes them to working ram. Thus tranfer will not start
--      at address 0 but at address 4.
--
--      Bit 10 of dma counter is used to release BUSRQ signal (1L).
--
--      In VHDL code buses are not resquested at all to cpu. Instead, working ram
--      address and data buses are muxed at hcnt(0) rate between cpu and dma.
--
--    Sprite data filtering and transfer from sprite buffer ram to line buffers:
--      For each scanline sprite buffer ram is fully(*) read, and data of sprites
--      which have graphics to be displayed on next line are written to sprite
--      line buffer. Reading address is managed by the same counter as the one
--      used for dma transfer (1F/2F/2E). But here this counter only drives 
--      sprite buffer ram addresses. Cpu address and data buses are not used for
--      that task and managed freely by cpu itself.
--
--      While reading sprite buffer ram sprite V (Y) position is sent to a line 
--      adder (3S/3R/3T) which determines if sprite belongs to the next line. In
--      that case sprite H (X) position is used to determine at which address of
--      the sprite line buffer the sprite data have to be written.
--
--      Sprite line buffer (1M/3M and 1P/3P) are 4x64x9bits rams used as
--      2 flip/flop buffer alternating every other line (odd/even) and each 
--      buffer is used as one 64x18bits ram.
--
--      In fact sprite H position bits 7 to 2 are used to address sprite line 
--      buffer and sprite H position bits 1 to 0 will be written to that buffer.
--
--      In the same way, since sprite are 16 lines height, bits 2 to 0 from 
--      sprite V position have to be written to the line buffer. (lsb of sprite 
--      lines count is made later from odd/even scanline counter and dont need
--      to be written to line buffer).
--
--      Finally at a given address, line buffer is written with:
--        - 2 least significants bits of sprite H position (2 pixels resolution)
--        - 3 least significants bits of sprite V position (2 lines resolution)
--        - 9 bits for sprite code (1bit shared with color)
--        - 2 bits for sprite color
--        - 2 bits for flip H/V attributes
-- 
--      Since line buffer address is only 6bits wide, corresponding to sprite H
--      position bits 7 to 2, one can immediatly see that if sprite are closer
--      than 4 steps position, the later written to the line buffer **may** 
--      completly override the former ones (for the given scanline).
--      
--		  (*) Only data from @1 to @160 are transfered to and read back. So only
--      159 sprites are taken into account. Anyway it's clear that working ram
--      is used for other task at upper addresses.
--
--    Sprite line buffer read:
--      After having been written during previous line, line buffer is read 
--      under horizontal video counter control (bits 3 to 8). Read data are used
--      to retrieve written sprite data.
--
--      Lsb of line counter and 3 least significants bits of V sprite position 
--      and sprite code are used to address graphics roms (taking into account
--      flip attributes).
--
--      2 least significant bits of H sprite position are used to delay sprite
--      color bits are graphics roms output in order to retrieve correct 
--      horizontal position. Counter at (5E) do this job by setting at the right
--      time SO/S1 of shift registers (4K/4L/4J/5K/4F/4H/4E/5F) and  CP of
--      register (4C).
--
--      Important role of sprite color (3bits) stored in line buffer:
--      One can see that counter at (5E) may be loaded with a value of 0-3 or a 
--      value of 8-11 depending on sprite color currently read from line buffer
--      (DJ14/15/16 thru NAND gate (3D) on shematics).
--
--        - When loaded with 8 to 11 the counter (5E) will reach 15 before being
--          (re)loaded. In that case shift registers (4K/../5F) and color register
--          (4C) will be loaded with new data to start displaying a NEW sprite.
--
--        - When loaded with 0 to 3 the counter (5E) will not reach 15 before
--          being (re)loaded. In that case shift registers (4K/../5F) and color
--          register (4C) continue to display previously started sprite. If no
--          new color triggers a load of counter with a value between 8 to 11,
--          the counter is periodicaly (re)loaded to a value between 0-3 and
--          don't reach 15. The started sprite continue to be displayed since
--          shift regsisters are not reloaded. Sprite display 'ends' after 16
--          pixels when shift registers outputs only '0'.
--
--        This also explain the role of (2D/2C)	AND gates on data input of line
--        buffer. This allow to 'clear' the line buffer just after reading. 
--        No color = No new sprite start.
--
--    So there are two sprite overlapping artefacts:
--
--      - line buffer address is only 6 bits => too close sprites may result in
--        last written sprite data to be completly replaced previously written
--        one for that scanline. This ocurs for sprites which H pos modulo 4 are
--        equal. Since sprite H/V positions have 2pixels/2lines resolution this
--        artefact may occur for sprites closer by less than 8 pixels.
--          
--      - line buffer doesn't contain sprite graphics but sprite data => sprite 
--        graphic roms are read at the same time as being displayed on screen and
--        since only 1 sprite can address graphics rom then only 1 sprite 
--        graphics is displayable at a time => As soon as a new sprite start being
--        displayed it stopped displaying previously started sprite EVEN IF THE
--        NEW SPRITE HAS TRANSPARENT COLORS for some pixels. This artefact always
--        occurs when sprite are closer than 16pixels but is visible only if 
--        first sprite still has non transparent colors to be displayed when 
--        second sprite begins.
--
--
--      Examples with sprite B being written after sprite A in line buffer
--      (ie @B > @A in working ram)
--
--        With H pos B = H pos A + 2 (but *NOT* at same line buffer address):
--
--         ________                      ________              ________
--        |  AAAA  |    ________        |  AAAA  |__          |  AAAA  |__
--        | AA  AA |   |        |       | AA        |         | AA  AA    |
--        |  AAAA  |   |  BBBB  |       |  A  BBBB  |         |  AAABBBB  |
--        | AA  AA |   | B    B | gives | AA B    B | instead | AA B    B |
--        |  AAAA  |   | B    B |       |  A B    B |   of    |  AAB    B |
--        |________|   |  BBBB  |       |__   BBBB  |         |__   BBBB  |
--                     |________|          |________|            |________|
--
--        With H pos B = H pos A + 2 (but at same line buffer address):
--
--         ________                      ________              ________
--        |  AAAA  |    ________        |  AAAA  |__          |  AAAA  |__
--        | AA  AA |   |        |       |           |         | AA  AA    |
--        |  AAAA  |   |  BBBB  |       |     BBBB  |         |  AAABBBB  |
--        | AA  AA |   | B    B | gives |    B    B | instead | AA B    B |
--        |  AAAA  |   | B    B |       |    B    B |   of    |  AAB    B |
--        |________|   |  BBBB  |       |__   BBBB  |         |__   BBBB  |
--                     |________|          |________|            |________|
--
--
--        With H pos B = H pos A :
--
--         ________                      ________             ________
--        |  AAAA  |    ________        |  AAAA  |           |  AAAA  |
--        | AA  AA |   |        |       |        |           | AA  AA |
--        |  AAAA  |   |  BBBB  |       |  BBBB  |           |  BBBB  |
--        | AA  AA |   | B    B | gives | B    B |  instead  | BA  AB |
--        |  AAAA  |   | B    B |       | B    B |    of     | BAAAAB |
--        |________|   |  BBBB  |       |  BBBB  |           |  BBBB  |
--                     |________|       |________|           |________|
--
--
--    VHDL code reproduces original hardware and doesn't try to avoid any of 
--    these artefacts
--
--    Protection device (7K/7J):
--      Algorithm is taken from MAME source code and seems to be ok for Popeye
--      and Sky skipper.
--
--    NMI hardware enable/disable is made by retriving cpu I register that is 
--    set to cpu address bus bits 15 to 8 during refresh cycle.
--
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity popeye is
port(
 clock_40     : in std_logic;
 reset        : in std_logic;
 tv15Khz_mode : in std_logic;
 video_r        : out std_logic_vector(2 downto 0);
 video_g        : out std_logic_vector(2 downto 0);
 video_b        : out std_logic_vector(1 downto 0);
 video_clk      : out std_logic;
 video_csync    : out std_logic;
 video_hblank   : out std_logic;
 video_vblank   : out std_logic;
 video_ce       : out std_logic;

 video_hs       : out std_logic;
 video_vs       : buffer std_logic;
 
 audio_out_l    : out std_logic_vector(15 downto 0);
 audio_out_r    : out std_logic_vector(15 downto 0);
  
 coin           : in std_logic;
 start1         : in std_logic;
 start2         : in std_logic;

 right1         : in std_logic;
 left1          : in std_logic;
 up1            : in std_logic;
 down1          : in std_logic;
 fire10         : in std_logic;
 fire11         : in std_logic;
 
 right2         : in std_logic;
 left2          : in std_logic;
 up2            : in std_logic;
 down2          : in std_logic;
 fire20         : in std_logic;
 fire21         : in std_logic;

 skyskipr       : in std_logic;

 sw1            : in std_logic_vector(6 downto 0);
 sw2            : in std_logic_vector(7 downto 0);
 
 service        : in std_logic;
 
 dl_addr        : in  std_logic_vector(16 downto 0);
 dl_wr          : in  std_logic;
 dl_data        : in  std_logic_vector( 7 downto 0)

 );
end popeye;

architecture struct of popeye is

 component T80s is
 	generic(
 		Mode    : integer := 0; -- 0 => Z80, 1 => Fast Z80, 2 => 8080, 3 => GB
 		T2Write : integer := 1; -- 0 => WR_n active in T3, /=0 => WR_n active in T2
 		IOWait  : integer := 1  -- 0 => Single cycle I/O, 1 => Std I/O cycle
 	);
 	port(
 		RESET_n : in std_logic;
 		CLK     : in std_logic;
 		CEN     : in std_logic := '1';
 		WAIT_n  : in std_logic := '1';
 		INT_n	  : in std_logic := '1';
 		NMI_n	  : in std_logic := '1';
 		BUSRQ_n : in std_logic := '1';
 		M1_n    : out std_logic;
 		MREQ_n  : out std_logic;
 		IORQ_n  : out std_logic;
 		RD_n    : out std_logic;
 		WR_n    : out std_logic;
 		RFSH_n  : out std_logic;
 		HALT_n  : out std_logic;
 		BUSAK_n : out std_logic;
 		OUT0    : in  std_logic := '0';  -- 0 => OUT(C),0, 1 => OUT(C),255
 		A       : out std_logic_vector(15 downto 0);
 		DI      : in std_logic_vector(7 downto 0);
 		DO      : out std_logic_vector(7 downto 0)
 	);
 end component T80s;

 signal reset_n   : std_logic;
 signal clock_vid : std_logic;
 signal clock_vidn: std_logic;
 signal clock_cnt1: std_logic_vector(3 downto 0) := "0000";
 signal clock_cnt2: std_logic_vector(4 downto 0) := "00000";

 signal hcnt    : std_logic_vector(9 downto 0) := (others=>'0'); -- horizontal counter
 signal hflip   : std_logic_vector(9 downto 0) := (others=>'0'); -- horizontal counter flip
 signal vcnt    : std_logic_vector(9 downto 0) := (others=>'0'); -- vertical counter
 signal vflip   : std_logic_vector(9 downto 0) := (others=>'0'); -- vertical counter flip
  
 signal hs_cnt, vs_cnt :std_logic_vector(9 downto 0) ;
 signal hsync0, hsync1, hsync2, hsync3, hsync4 : std_logic;
 signal top_frame : std_logic := '0';
 signal init_eo   : std_logic;
 
 signal pix_ena     : std_logic;
 signal cpu_ena     : std_logic;

 signal cpu_addr    : std_logic_vector(15 downto 0);
 signal cpu_di      : std_logic_vector( 7 downto 0);
 signal cpu_do      : std_logic_vector( 7 downto 0);
 signal cpu_wr_n    : std_logic;
 signal cpu_wr_n_r  : std_logic;
 signal cpu_rd_n    : std_logic;
 signal cpu_mreq_n  : std_logic;
 signal cpu_ioreq_n : std_logic;
 signal cpu_nmi_n   : std_logic;
 signal cpu_m1_n    : std_logic;
 signal cpu_rfsh_n  : std_logic;
 
 signal nmi_enable  : std_logic;
 signal no_nmi      : std_logic;
  
 signal cpu_rom_addr   : std_logic_vector(14 downto 0);
 signal cpu_rom_do     : std_logic_vector( 7 downto 0);
 signal cpu_rom_do_swp : std_logic_vector( 7 downto 0);
 
 signal wram_addr   : std_logic_vector(11 downto 0);
 signal wram_we     : std_logic;
 signal wram_do     : std_logic_vector( 7 downto 0);
 signal wram_do_r   : std_logic_vector( 7 downto 0);

 signal ch_ram_addr     : std_logic_vector(9 downto 0);
 signal ch_ram_txt_we   : std_logic;
 signal ch_ram_txt_do   : std_logic_vector(7 downto 0);
 signal ch_ram_color_we : std_logic;
 signal ch_ram_color_do : std_logic_vector(3 downto 0);
 
 signal ch_code      : std_logic_vector( 7 downto 0);
 signal ch_code_line : std_logic_vector(11 downto 0);
 signal ch_graphx_do : std_logic_vector( 7 downto 0);
 signal ch_vid       : std_logic;
 signal ch_color     : std_logic_vector( 4 downto 0);
 
 signal hoffset      : std_logic_vector( 8 downto 0);
 signal hshift       : std_logic_vector( 9 downto 0);
 signal voffset      : std_logic_vector( 7 downto 0);
 signal vshift       : std_logic_vector( 9 downto 0);

 signal bg_ram_addr    : std_logic_vector(12 downto 0);
 signal bg_ram_lnib_we : std_logic;
 signal bg_ram_lnib_do : std_logic_vector(3 downto 0);
 signal bg_ram_hnib_we : std_logic;
 signal bg_ram_hnib_do : std_logic_vector(3 downto 0);

 signal bg_graphx    : std_logic_vector(3 downto 0); 
 signal bg_color     : std_logic_vector(3 downto 0); 
  
 signal move_buf          : std_logic;
 signal read_buf          : std_logic;
 signal sp_ram_addr       : std_logic_vector(9 downto 0);
 signal sp_ram1_we        : std_logic;
 signal sp_ram1_do        : std_logic_vector(7 downto 0);
 signal sp_ram2_we        : std_logic;
 signal sp_ram2_do        : std_logic_vector(7 downto 0);
 signal sp_ram3_we        : std_logic;
 signal sp_ram3_do        : std_logic_vector(7 downto 0);
 signal sp_ram4_we        : std_logic;
 signal sp_ram4_do        : std_logic_vector(7 downto 0);

 signal sp_vcnt           : std_logic_vector(9 downto 0);
 signal sp_on_line        : std_logic;
 
 signal sp_buffer_ram1_addr : std_logic_vector( 5 downto 0);
 signal sp_buffer_ram1_we   : std_logic;
 signal sp_buffer_ram1_di   : std_logic_vector(17 downto 0);
 signal sp_buffer_ram1_do   : std_logic_vector(17 downto 0);
 
 signal sp_buffer_ram2_addr : std_logic_vector( 5 downto 0);
 signal sp_buffer_ram2_we   : std_logic;
 signal sp_buffer_ram2_di   : std_logic_vector(17 downto 0);
 signal sp_buffer_ram2_do   : std_logic_vector(17 downto 0);
 
 signal sp_buffer_sel       : std_logic;

 signal sp_graphx1_do    : std_logic_vector( 7 downto 0);
 signal sp_graphx2_do    : std_logic_vector( 7 downto 0);
 signal sp_graphx3_do    : std_logic_vector( 7 downto 0);
 signal sp_graphx4_do    : std_logic_vector( 7 downto 0);

 signal sp_graphx0    : std_logic_vector( 15 downto 0);
 signal sp_graphx_sr0 : std_logic_vector( 15 downto 0);
 signal sp_graphx1    : std_logic_vector( 15 downto 0);
 signal sp_graphx_sr1 : std_logic_vector( 15 downto 0);
 
 signal sp_code_line        : std_logic_vector(12 downto 0);
 signal sp_code_line0       : std_logic_vector(12 downto 0);
 
 signal sp_hflip            : std_logic;
 signal sp_hflip_r          : std_logic;
 signal sp_hflip_rr         : std_logic;
 signal sp_hoffset          : std_logic_vector(1 downto 0);
 signal sp_color            : std_logic_vector(2 downto 0);
 signal sp_color_r          : std_logic_vector(2 downto 0);
 signal sp_color_rr         : std_logic_vector(2 downto 0);
 signal sp_vid              : std_logic_vector(1 downto 0);
 signal sp_hcnt             : std_logic_vector(3 downto 0);
 
 signal ch_palette_addr        : std_logic_vector(4 downto 0);
 signal ch_palette_do          : std_logic_vector(7 downto 0);
 signal bg_palette_addr        : std_logic_vector(4 downto 0);
 signal bg_palette_do          : std_logic_vector(7 downto 0);
 signal sp_palette_addr        : std_logic_vector(7 downto 0);
 signal sp_palette_rg_do       : std_logic_vector(7 downto 0); -- only 4 bits used
 signal sp_palette_gb_do       : std_logic_vector(7 downto 0); -- only 4 bits used
 
 signal input_0   : std_logic_vector(7 downto 0);
 signal input_1   : std_logic_vector(7 downto 0);
 signal input_2   : std_logic_vector(7 downto 0);
  
 signal ay_do     : std_logic_vector(7 downto 0);
 signal ay_bdir   : std_logic;
 signal ay_bc1    : std_logic;
 signal ay_audio  : std_logic_vector(7 downto 0);
 signal ay_ena    : std_logic;
 
 signal ay_iob_do : std_logic_vector(7 downto 0);
 signal ay_ioa_di : std_logic_vector(7 downto 0);
 
 signal protection_data0 : std_logic_vector(7 downto 0);
 signal protection_data1 : std_logic_vector(7 downto 0);
 signal protection_do    : std_logic_vector(7 downto 0);
 signal protection_shift : std_logic_vector(2 downto 0);
 
 signal cpu_rom_we      : std_logic;
 signal ch_graphics_we  : std_logic;
 signal sp_graphics1_we : std_logic;
 signal sp_graphics2_we : std_logic;
 signal sp_graphics3_we : std_logic;
 signal sp_graphics4_we : std_logic;
 signal sp_palette1_we  : std_logic;
 signal sp_palette2_we  : std_logic;
 signal ch_palette_we   : std_logic;
 signal bg_palette_we   : std_logic;
 
begin

clock_vid  <= clock_40;
clock_vidn <= not clock_40;
reset_n    <= not reset;

-- make enables clock from clock_vid
process (clock_vid, reset)
begin
	if reset='1' then
		clock_cnt1 <= (others=>'0');
		clock_cnt2 <= (others=>'0');
	else 
		if rising_edge(clock_vid) then
		
			if clock_cnt1 = "1111" then  -- divide by 16
				clock_cnt1 <= (others=>'0');
			else
				clock_cnt1 <= clock_cnt1 + 1;
			end if;
			
			if clock_cnt2 = "10011" then  -- divide by 20
				clock_cnt2 <= (others=>'0');
			else
				clock_cnt2 <= clock_cnt2 + 1;
			end if;
			
		end if;
	end if;   		
end process;
--
cpu_ena <= '1' when clock_cnt2 = "00000" or clock_cnt2 = "01010" else '0'; -- (4MHz for cpu)
						  
ay_ena  <= '1' when clock_cnt2 = "00000" else '0';                         -- (2MHz for ay-3-8910)

pix_ena <= '1' when (clock_cnt1(1 downto 0) = "11" and tv15Khz_mode = '1') or         -- (10MHz for video interleaved)
						  (clock_cnt1(0) = '1'           and tv15Khz_mode = '0') else '0';  -- (20MHz for video progressive)

video_clk <= clock_vid;
video_ce <= pix_ena;
						  
-----------------------------------
-- Video scanner  640x512 @20Mhz --
--                640x256 @10Mhz --
-- display 512x448               --
-----------------------------------
process (reset, clock_vid)
begin
	if reset='1' then
		hcnt  <= (others=>'0');
		vcnt  <= (others=>'0');
		top_frame <= '0';
	else
		if rising_edge(clock_vid) then
			if pix_ena = '1' then
		
				hcnt <= hcnt + 1;
				if hcnt = 639 then
					hcnt <= (others=>'0');
					vcnt <= vcnt + 1;
					if (vcnt = 525 and tv15Khz_mode = '0') or (vcnt = 262 and tv15Khz_mode = '1') then -- extension to classic video standard
						vcnt <= (others=>'0');
						top_frame <= not top_frame;
					end if;
				end if;
			
				if tv15Khz_mode = '0' then 
					--	progessive mode
				
					-- tune 31kHz vertical screen position here
					if vcnt = 490+8 then video_vs <= '0'; end if; -- front porch 10
					if vcnt = 492+8 then video_vs <= '1'; end if; -- sync pulse   2
																				 -- back porch  33 
					-- tune 31kHz horizontal screen position here	
					if hcnt = 512+13+12 then video_hs <= '0'; end if; -- front porch 16/25*20 = 13
					if hcnt = 512+90+12 then video_hs <= '1'; end if; -- sync pulse  96/25*20 = 77
																				       -- back porch  48/25*20 = 38
					video_hblank <= '1';
					if hcnt >= 0+16 and  hcnt < 512+16 and
						vcnt >= 32 and  vcnt < 480 then video_hblank <= '0';
					end if;
				
					video_vblank <= '1';
					if vcnt >= 32 and vcnt < 480 then
						video_vblank <= '0';
					end if;
						
				
				else -- interlaced mode
				 
					if hcnt = 530+18 then            -- tune 15KHz horizontal screen position here
						hs_cnt <= (others => '0');
						if (vcnt = 248) then          -- tune 15KHz vertical screen position here
							vs_cnt <= (others => '0');
						else
							vs_cnt <= vs_cnt +1;
						end if;
					else 
						hs_cnt <= hs_cnt + 1;
					end if;

					if hcnt = 0+16 then
						video_hblank <= '0';
						video_vblank <= '1';
						if vcnt >= 16 and vcnt < 240 then
							video_vblank <= '0';
						end if;
					end if;

					if hcnt = 512+16 then
						video_hblank <= '1';
					end if;

					if    hs_cnt =  0 then hsync0 <= '0'; video_hs <= '0';
					elsif hs_cnt = 47 then hsync0 <= '1'; video_hs <= '1';
					end if;
					
					if    hs_cnt =      0  then hsync1 <= '0';
					elsif hs_cnt =     23  then hsync1 <= '1';
					elsif hs_cnt = 320+ 0  then hsync1 <= '0';
					elsif hs_cnt = 320+23  then hsync1 <= '1';
					end if;
			
					if    hs_cnt =      0  then hsync2 <= '0';
					elsif hs_cnt = 320-47  then hsync2 <= '1';
					elsif hs_cnt = 320     then hsync2 <= '0';
					elsif hs_cnt = 640-47  then hsync2 <= '1';
					end if;

					if    hs_cnt =      0  then hsync3 <= '0';
					elsif hs_cnt =     23  then hsync3 <= '1';
					elsif hs_cnt = 320     then hsync3 <= '0';
					elsif hs_cnt = 640-47  then hsync3 <= '1';
					end if;

					if    hs_cnt =      0  then hsync4 <= '0';
					elsif hs_cnt = 320-47  then hsync4 <= '1';
					elsif hs_cnt = 320     then hsync4 <= '0';
					elsif hs_cnt = 320+23  then hsync4 <= '1';
					end if;

					if     vs_cnt =  1 then video_csync <= hsync1;
					elsif  vs_cnt =  2 then video_csync <= hsync1;
					elsif  vs_cnt =  3 then video_csync <= hsync1;
					elsif  vs_cnt =  4 and top_frame = '1' then video_csync <= hsync3;
					elsif  vs_cnt =  4 and top_frame = '0' then video_csync <= hsync1;
					elsif  vs_cnt =  5 then video_csync <= hsync2;
					elsif  vs_cnt =  6 then video_csync <= hsync2;
					elsif  vs_cnt =  7 and  top_frame = '1' then video_csync <= hsync4;
					elsif  vs_cnt =  7 and  top_frame = '0' then video_csync <= hsync2;
					elsif  vs_cnt =  8 then video_csync <= hsync1;
					elsif  vs_cnt =  9 then video_csync <= hsync1;
					elsif  vs_cnt = 10 then video_csync <= hsync1;
					elsif  vs_cnt = 11 then video_csync <= hsync0;
					else                    video_csync <= hsync0;
					end if;

					if vcnt = 250 then video_vs <= '0'; end if;
					if vcnt = 252 then video_vs <= '1'; end if;

				end if;

			end if;
		end if;
	end if;
end process;

--------------------
-- players inputs --
--------------------
init_eo <= top_frame;

input_0 <= fire11 & "00" & fire10 & down1 & up1 & left1 & right1;
input_1 <= fire21 & "00" & fire20 & down2 & up2 & left2 & right2;
input_2 <= coin & service & '0' & init_eo & start2 & start1 & "00";

------------------------------------------
-- cpu data input with address decoding --
------------------------------------------
cpu_rom_addr <= 
	(cpu_addr(14 downto 10) & cpu_addr(8 downto 7) & cpu_addr(0) & cpu_addr(1) & cpu_addr(2) & cpu_addr(4) & cpu_addr(5) & cpu_addr(9) & cpu_addr(3) & cpu_addr(6)) xor ("000" & x"0FC") when skyskipr = '1' else
	(cpu_addr(14 downto 10) & cpu_addr(8 downto 6) & cpu_addr(3) & cpu_addr(9) & cpu_addr(5 downto 4) & cpu_addr(2 downto 0)) xor ("000" & x"03F");

cpu_rom_do_swp <=
	cpu_rom_do(3) & cpu_rom_do(4) & cpu_rom_do(2) & cpu_rom_do(5) &
	cpu_rom_do(1) & cpu_rom_do(6) & cpu_rom_do(0) & cpu_rom_do(7);
	
cpu_di <= cpu_rom_do_swp	 when cpu_mreq_n  = '0' and cpu_addr(15 downto 12) < X"8" else    -- program rom 0000-7FFF 32Ko
			 wram_do_r   		 when cpu_mreq_n  = '0' and (cpu_addr and X"F800") = x"8000" and skyskipr = '1' else -- work    ram 8000-87FF  2Ko
			 wram_do_r   		 when cpu_mreq_n  = '0' and (cpu_addr and X"FC00") = x"8C00" and skyskipr = '1' else -- work    ram 8C00-8FFF  1Ko
			 wram_do_r   		 when cpu_mreq_n  = '0' and (cpu_addr and X"E000") = x"8000" and skyskipr = '0' else -- work    ram 8000-87FF  2Ko + mirroring 1800
			 protection_do     when cpu_mreq_n  = '0' and (cpu_addr and X"FFFF") = x"E000" else -- protection E000
			 X"00"             when cpu_mreq_n  = '0' and (cpu_addr and X"FFFF") = x"E001" else -- protection E001
   		 input_0           when cpu_ioreq_n = '0' and (cpu_addr(1 downto 0) = "00") else
   		 input_1           when cpu_ioreq_n = '0' and (cpu_addr(1 downto 0) = "01") else
   		 input_2           when cpu_ioreq_n = '0' and (cpu_addr(1 downto 0) = "10") else
   		 ay_do             when cpu_ioreq_n = '0' and (cpu_addr(1 downto 0) = "11") else
   		 X"FF";
--
------------------------------------------
-- write enable / ram access from CPU --
------------------------------------------
wram_addr <= (skyskipr and cpu_addr(11)) & cpu_addr(10 downto 0) when hcnt(0) = '0' else skyskipr & '1' & sp_ram_addr(9 downto 0);

wram_we         <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"F000") = x"8000" and hcnt(0) = '0' and skyskipr = '1' else 
                   '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"E000") = x"8000" and hcnt(0) = '0' else '0';
ch_ram_txt_we   <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"EC00") = x"A000" and hcnt(0) = '0' else '0';
ch_ram_color_we <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"EC00") = x"A400" and hcnt(0) = '0' else '0';
bg_ram_lnib_we  <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"F000") = x"C000" and hcnt(0) = '0' else '0';
bg_ram_hnib_we  <= '1' when cpu_mreq_n = '0' and cpu_wr_n = '0' and (cpu_addr and x"F000") = x"D000" and hcnt(0) = '0' else '0';

-----------------------------------------------------
-- Transfer sprite data from wram to sprite ram 
-- once per frame. Read sprite ram on every scanline.
-----------------------------------------------------
sp_ram1_we   <= hcnt(0) when move_buf = '1' and sp_ram_addr(1 downto 0) = "00" else '0';
sp_ram2_we   <= hcnt(0) when move_buf = '1' and sp_ram_addr(1 downto 0) = "01" else '0';
sp_ram3_we   <= hcnt(0) when move_buf = '1' and sp_ram_addr(1 downto 0) = "10" else '0';
sp_ram4_we   <= hcnt(0) when move_buf = '1' and sp_ram_addr(1 downto 0) = "11" else '0';

process (clock_vid)
begin
	if rising_edge(clock_vid) then
	
		if hcnt(0) = '0' then wram_do_r <= wram_do; end if;
	
		if move_buf = '0' and read_buf ='0' then 
			sp_ram_addr <= "00" & X"04" ; -- data from 00 to 03 aren't sprite data
			                              -- they are managed at Misc registers level (@8C00-03)

			if hcnt = 1 and pix_ena = '1' then
				if (vcnt = 500 and tv15Khz_mode = '0') or	(vcnt = 250 and tv15Khz_mode = '1') then
					move_buf <= '1';
				else 
					read_buf <= '1';
				end if;
			end if;			
		end if;
		
		if move_buf = '1' and pix_ena = '1' and hcnt(0) = '1' then
			if sp_ram_addr >= 640 then 
				move_buf <= '0';
			else 
				sp_ram_addr <= sp_ram_addr + 1;
			end if;	
		end if;

		if read_buf = '1' and pix_ena = '1' and hcnt(0) = '1' then
			if sp_ram_addr >= 640 then 
				read_buf <= '0';
			else 
				sp_ram_addr <= sp_ram_addr + 4;
			end if;	
		end if;
		
	end if;
end process;

------------------------------------------------------------------------
-- Misc registers : write enable / interrupt / ay-3-8910 IF
------------------------------------------------------------------------

process (clock_vid, reset)
begin
	if reset = '1' then 
		nmi_enable <= '0';
		no_nmi <= '0';
		hoffset <= (others => '0');
	else

	if rising_edge(clock_vid) then

		cpu_wr_n_r <= cpu_wr_n;
	
		if cpu_mreq_n = '0' and cpu_wr_n = '0' then 
			if (cpu_addr = x"8C00") then hoffset(7 downto 0) <= cpu_do; end if;
			if (cpu_addr = x"8C01") then voffset <= cpu_do; end if;
			if (cpu_addr = x"8C02") then hoffset(8) <= cpu_do(0) and skyskipr; end if;
			
			if (cpu_addr = x"8C03") then
				if skyskipr = '1' then
					sp_palette_addr(7 downto 5) <=  '0' & cpu_do(0) & cpu_do(0); --cpu_do(2 downto 0);
				else
					sp_palette_addr(7 downto 5) <= cpu_do(2 downto 0);
				end if;
				bg_palette_addr(4) <= cpu_do(3);
			end if;
	
			if (cpu_addr = x"E000") then protection_shift <= cpu_do(2 downto 0); end if;
			if (cpu_addr = x"E001") and cpu_wr_n_r = '1' then
				protection_data0 <= protection_data1;
				protection_data1 <= cpu_do;
			end if;
	
		end if;
		
		-- during rsfh cpu_addr(15 downto 8) contains cpu register I
		-- lsb used to enable/disable nmi signal
		if cpu_rfsh_n = '0' and cpu_mreq_n = '0' then
			nmi_enable <= cpu_addr(8);
		end if;

		-- trick to prevent nmi to occur during call 2f93 @3043
		-- otherwise game crash
		-- maybe not needed when nb scanline = 511 (31kHz) or 255 (15kHz)
		if (cpu_addr = x"3043") and cpu_m1_n = '0' then 
			no_nmi <= skyskipr;
		end if;

		if (cpu_addr = x"3046") and cpu_m1_n = '0' then 
			no_nmi <= '0';
		end if;
		
	end if;
	
	end if;
end process;

protection_do <=
	(protection_data1(7 downto 0)      ) or ( "00000000"                               )  when protection_shift = "000" else
	(protection_data1(6 downto 0) & '0' ) or ( "0000000" & protection_data0(7 downto 7))  when protection_shift = "001" else
	(protection_data1(5 downto 0) & "00" ) or ( "000000" & protection_data0(7 downto 6))  when protection_shift = "010" else
	(protection_data1(4 downto 0) & "000" ) or ( "00000" & protection_data0(7 downto 5))  when protection_shift = "011" else
	(protection_data1(3 downto 0) & "0000" ) or ( "0000" & protection_data0(7 downto 4))  when protection_shift = "100" else
	(protection_data1(2 downto 0) & "00000" ) or ( "000" & protection_data0(7 downto 3))  when protection_shift = "101" else
	(protection_data1(1 downto 0) & "000000" ) or ( "00" & protection_data0(7 downto 2))  when protection_shift = "110" else
	(protection_data1(0 downto 0) & "0000000" ) or ( '0' & protection_data0(7 downto 1)); --   protection_shift = "111"

cpu_nmi_n <= '0' when nmi_enable = '1' and no_nmi = '0' and video_vs = '0' else '1';

audio_out_l <= ay_audio & ay_audio;
audio_out_r <= ay_audio & ay_audio;
-- 
-- bdir bc1 (bc2 = 1)
--  0    0 : Inactive
--  0    1 : Read
--  1    0 : Write
--  1    1 : Address

ay_bdir <= '1' when cpu_ioreq_n = '0' and  cpu_wr_n = '0' else '0';
ay_bc1  <= '1' when cpu_ioreq_n = '0' and (cpu_rd_n = '0' or (cpu_wr_n = '0' and cpu_addr(0) = '0')) else '0';

ay_ioa_di <= not sw2(to_integer(unsigned(ay_iob_do(3 downto 1)))) & not sw1;

------------------------------------
---------- sprite machine ----------
------------------------------------
hflip <= hcnt;       -- do not apply mirror horizontal flip
vflip <= vcnt(8 downto 0) & not top_frame when tv15Khz_mode = '1' else vcnt; -- do not apply mirror flip

sp_buffer_sel <= vflip(1) when tv15Khz_mode = '1' else vflip(0);

sp_vcnt <= vflip + (sp_ram2_do & '0') - 14 when tv15Khz_mode = '1' else -- tune v sprite position for 15KHz (interlaced)
			  vflip + (sp_ram2_do & '0') - 15;                             -- tune v sprite position for 31KHz (progressive)

sp_on_line <= '1' when (sp_vcnt(8 downto 4) = (x"F"&'1')) and (read_buf = '1') else '0';

-- feed and read line buffers
						
-- sprite buffer ram data (order differ w.r.t. Popeye schematics) :
--   (  2 -  0 ) sprite v pos bits(3-1)
--   (  9 -  3 ) sprite code bits(6-0)
--   (    - 10 ) sprite flip h
--   ( 12 - 11 ) sprite h pos bits(1-0)
--   ( 14 - 13 ) sprite color bits(1-0) 
--   (    - 15 ) sprite color bit(2) (AND sprite code bit(8) for Popeye but n.u. for Sky Skipper)
--   (    - 16 ) sprite flip v
--   (    - 17 ) sprite code bit(7)
						
sp_buffer_ram1_di   <= sp_ram4_do(4 downto 0) & sp_ram1_do(1 downto 0) & sp_ram3_do & sp_vcnt(3 downto 1) when sp_buffer_sel = '1' else "00"&x"0000";
sp_buffer_ram1_addr <= sp_ram1_do(7 downto 2)                                                             when sp_buffer_sel = '1' else hflip(8 downto 3);
sp_buffer_ram1_we   <= pix_ena and hcnt(0) and sp_on_line                                                 when sp_buffer_sel = '1' else pix_ena and hcnt(2) and hcnt(1) and hcnt(0);

sp_buffer_ram2_di   <= sp_ram4_do(4 downto 0) & sp_ram1_do(1 downto 0) & sp_ram3_do & sp_vcnt(3 downto 1) when sp_buffer_sel = '0' else "00"&x"0000";
sp_buffer_ram2_addr <= sp_ram1_do(7 downto 2)                                                             when sp_buffer_sel = '0' else hflip(8 downto 3);
sp_buffer_ram2_we   <= pix_ena and hcnt(0) and sp_on_line                                                 when sp_buffer_sel = '0' else pix_ena and hcnt(2) and hcnt(1) and hcnt(0);

sp_code_line0 <= 
 (sp_buffer_ram1_do(15) & sp_buffer_ram1_do(17) & sp_buffer_ram1_do(9 downto 0) & sp_vcnt(0)) xor ('0' & x"00F") when sp_buffer_sel = '0' and sp_buffer_ram1_do(16) = '1' else
 (sp_buffer_ram1_do(15) & sp_buffer_ram1_do(17) & sp_buffer_ram1_do(9 downto 0) & sp_vcnt(0)) xor ('0' & x"000") when sp_buffer_sel = '0' and sp_buffer_ram1_do(16) = '0' else
 (sp_buffer_ram2_do(15) & sp_buffer_ram2_do(17) & sp_buffer_ram2_do(9 downto 0) & sp_vcnt(0)) xor ('0' & x"00F") when sp_buffer_sel = '1' and sp_buffer_ram2_do(16) = '1' else
 (sp_buffer_ram2_do(15) & sp_buffer_ram2_do(17) & sp_buffer_ram2_do(9 downto 0) & sp_vcnt(0)) xor ('0' & x"000");
				  
sp_code_line <= sp_code_line0 xor ('1' & x"FFF") when tv15Khz_mode = '1' else -- ok for 15 KHz
                sp_code_line0 xor ('1' & x"FFE");                             -- ok for 31 KHz

sp_hflip     <= sp_buffer_ram1_do(10)           when sp_buffer_sel = '0' else sp_buffer_ram2_do(10);
sp_hoffset   <= sp_buffer_ram1_do(12 downto 11) when sp_buffer_sel = '0' else sp_buffer_ram2_do(12 downto 11);
sp_color     <= sp_buffer_ram1_do(15 downto 13) when sp_buffer_sel = '0' else sp_buffer_ram2_do(15 downto 13);

process (clock_vid)
begin
	if rising_edge(clock_vid) then

		if pix_ena = '1' then 
		
			if hcnt(2 downto 0) = "111"  then 
				
				sp_graphx0 <= sp_graphx1_do & sp_graphx2_do;
				sp_graphx1 <= sp_graphx3_do & sp_graphx4_do;
				sp_color_r <= sp_color;
				sp_hflip_r <= sp_hflip;
					
				if sp_color = "000" then 
					sp_hcnt <= "01" & not sp_hoffset;
				else
					sp_hcnt <= "11" & not sp_hoffset;			
				end if;
			
			else		
				if hcnt(0)='1' then sp_hcnt <= sp_hcnt + 1; end if;			
			end if;
		
			if hcnt(0) = '0' and sp_hcnt = x"F" then 
				sp_graphx_sr0 <= sp_graphx0;
				sp_graphx_sr1 <= sp_graphx1;
				sp_color_rr   <= sp_color_r;
				sp_hflip_rr   <= sp_hflip_r;
			else
				if sp_hflip_rr = '0' then 
					sp_graphx_sr0 <= '0' & sp_graphx_sr0(15 downto 1);
					sp_graphx_sr1 <= '0' & sp_graphx_sr1(15 downto 1);
				else
					sp_graphx_sr0 <= sp_graphx_sr0(14 downto 0) & '0';
					sp_graphx_sr1 <= sp_graphx_sr1(14 downto 0) & '0';
				end if;
			end if;
							
		end if;
	end if;
end process;

sp_palette_addr(1 downto 0) <= sp_graphx_sr0(0) & sp_graphx_sr1(0) when sp_hflip_rr = '0' else sp_graphx_sr0(15) & sp_graphx_sr1(15);
sp_palette_addr(4 downto 2) <= sp_color_rr;

----------------------------
------- char machine -------
----------------------------
ch_ram_addr <= cpu_addr(9 downto 0) when hcnt(0) = '0' else vflip(8 downto 4) & hflip(8 downto 4);

ch_code_line <= '1' & ch_code & vflip(3 downto 1);

process (clock_vid)
begin
	if rising_edge(clock_vid) then
	
		if pix_ena = '1' then
		
			if hcnt(0) = '1' then
				if hcnt(3 downto 1) = "111" then
					ch_code <= ch_ram_txt_do;
					ch_color <= ch_ram_color_do(3) & ch_ram_color_do;
				end if;
			end if;	
			
			ch_palette_addr <= ch_color;
			ch_vid <= ch_graphx_do(to_integer(unsigned(hflip(3 downto 1))));
			
		end if;

	end if;
end process;


----------------------------
---- background machine ----
----------------------------
bg_ram_addr <= cpu_addr(11 downto 6) & cpu_do(7) & cpu_addr(5 downto 0) when hcnt(0) = '0' and skyskipr = '1' else
               vshift(8 downto 3) & hshift(9 downto 3)  when hcnt(0) = '1' and skyskipr = '1' else
               '0' & cpu_addr(11 downto 0) when hcnt(0) = '0' else
               '0' & vshift(7 downto 2) & hshift(8 downto 3);

process (clock_vid)
begin
	if rising_edge(clock_vid) then

		if pix_ena = '1' then
		
			if hcnt = 540 then -- tune background h pos w.r.t char (use odd value to keep hshift(0) = hcnt(0))
				hshift <= hoffset & '0'; 
			else
				hshift <= hshift + 1 ;
			end if;
			
			if hcnt = 540 then 
				if tv15Khz_mode = '0' then
				 vshift <= ('0' & voffset & '0') + vflip + ('0' & not skyskipr & x"01"); -- tune background v pos w.r.t char
				else
				 vshift <= ('0' & voffset & '0') + vflip + ('0' & not skyskipr & x"02"); -- tune background v pos w.r.t char
				end if;
			end if;
				
			if hcnt(0) = '1' then
				if hcnt(1) = '1' then
					if skyskipr = '1' then
						if vshift(9) = '1' then
							bg_color <= bg_ram_lnib_do;
						else
							bg_color <= (others => '0');
						end if;
					else
						if vshift(8) = '1' then
							bg_color <= bg_ram_lnib_do;
						else
							bg_color <= bg_ram_hnib_do;
						end if;
					end if;
				end if;
			end if;
		
			bg_palette_addr(3 downto 0) <= bg_color;

		end if;

	end if;
end process;
	
---------------------------
-- mux char/sprite video --
---------------------------
process (clock_vid)
begin
	if rising_edge(clock_vid) then
	
		if (voffset = x"00" and skyskipr = '1') or (hoffset = x"00" and skyskipr = '0') then
			video_r <= "000";
			video_g <= "000";
			video_b <= "00";
		else
			video_r <= not bg_palette_do(2 downto 0);
			video_g <= not bg_palette_do(5 downto 3);
			video_b <= not bg_palette_do(7 downto 6);
		end if;

		if sp_palette_addr(1 downto 0) /= "00" then
			video_r <= not (sp_palette_rg_do(2 downto 0));
			video_g <= not (sp_palette_gb_do(1 downto 0) & sp_palette_rg_do(3));
			video_b <= not (sp_palette_gb_do(3 downto 2));
		end if;
				
		if ch_vid = '1' then
			video_r <= not ch_palette_do(2 downto 0);
			video_g <= not ch_palette_do(5 downto 3);
			video_b <= not ch_palette_do(7 downto 6);
		end if;
		
	end if;
end process;		
		
------------------------------
-- components & sound board --
------------------------------

-- microprocessor Z80
cpu : component T80s
generic map(Mode => 0, T2Write => 1, IOWait => 1)
port map(
  RESET_n => reset_n,
  CLK     => clock_vid,
  CEN     => cpu_ena,
  WAIT_n  => '1',
  INT_n   => '1', -- cpu_irq_n,
  NMI_n   => cpu_nmi_n,
  BUSRQ_n => '1',
  M1_n    => cpu_m1_n,
  MREQ_n  => cpu_mreq_n,
  IORQ_n  => cpu_ioreq_n,
  RD_n    => cpu_rd_n,
  WR_n    => cpu_wr_n,
  RFSH_n  => cpu_rfsh_n,
  HALT_n  => open,
  BUSAK_n => open,
  A       => cpu_addr,
  DI      => cpu_di,
  DO      => cpu_do
);

-- cpu program ROM 0x0000-0x7FFF
--rom_cpu : entity work.popeye_cpu
--rom_cpu : entity work.popeye_cpu_protected
--port map(
-- clk  => clock_vidn,
-- addr => cpu_rom_addr,
-- data => cpu_rom_do
--);

rom_cpu : entity work.dpram
generic map( dWidth => 8, aWidth => 15)
port map(
 clk_a  => clock_vidn,
 addr_a => cpu_rom_addr,
 q_a    => cpu_rom_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(14 downto 0),
 we_b   => cpu_rom_we,
 d_b    => dl_data
);

cpu_rom_we <= '1' when dl_wr = '1' and dl_addr(16 downto 15) = "00" else '0'; -- 00000-07FFF

-- working RAM   8000-87FF/8800-8FFF  2Ko
wram : entity work.gen_ram
generic map( dWidth => 8, aWidth => 12)
port map(
 clk  => clock_vidn,
 we   => wram_we,
 addr => wram_addr,
 d    => cpu_do,
 q    => wram_do
);

-- char RAM (text)  A000-A3FF  1Ko + mirroring 1000
char_ram_txt : entity work.gen_ram
generic map( dWidth => 8, aWidth => 10)
port map(
 clk  => clock_vidn,
 we   => ch_ram_txt_we,
 addr => ch_ram_addr,
 d    => cpu_do,
 q    => ch_ram_txt_do
);

-- char RAM (color)  A400-A7FF  1Ko + mirroring 1000
char_ram_color : entity work.gen_ram
generic map( dWidth => 4, aWidth => 10)
port map(
 clk  => clock_vidn,
 we   => ch_ram_color_we,
 addr => ch_ram_addr,
 d    => cpu_do(3 downto 0),
 q    => ch_ram_color_do
);

-- video RAM   C000-CFFF  4K x 4bits 
video_ram_lnib : entity work.gen_ram
generic map( dWidth => 4, aWidth => 13)
port map(
 clk  => clock_vidn,
 we   => bg_ram_lnib_we,
 addr => bg_ram_addr,
 d    => cpu_do(3 downto 0),
 q    => bg_ram_lnib_do
);

-- video RAM   D000-DFFF  4K x 4bits 
video_ram_hnib : entity work.gen_ram
generic map( dWidth => 4, aWidth => 13)
port map(
 clk  => clock_vidn,
 we   => bg_ram_hnib_we,
 addr => bg_ram_addr,
 d    => cpu_do(3 downto 0),
 q    => bg_ram_hnib_do
);


--------------------------------
-- debug obj RAM
--------------------------------
--dbg_obj_ram : entity work.obj_ram
--generic map( dWidth => 8, aWidth => 10)
--port map(
-- clk  => clock_vidn,
-- we   => '0',
-- addr => wram_addr(9 downto 0),
-- d    => x"FF",
-- q    => dbg_wram_do
--);
--------------------------------
--------------------------------
	
-- sprite RAMs (no cpu access)
sprite_ram1 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk  => clock_vidn,
 we   => sp_ram1_we,
 addr => sp_ram_addr(9 downto 2),
 d    => wram_do,
 q    => sp_ram1_do
);

sprite_ram2 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk  => clock_vidn,
 we   => sp_ram2_we,
 addr => sp_ram_addr(9 downto 2),
 d    => wram_do,
 q    => sp_ram2_do
);

sprite_ram3 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk  => clock_vidn,
 we   => sp_ram3_we,
 addr => sp_ram_addr(9 downto 2),
 d    => wram_do,
 q    => sp_ram3_do
);

sprite_ram4 : entity work.gen_ram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk  => clock_vidn,
 we   => sp_ram4_we,
 addr => sp_ram_addr(9 downto 2),
 d    => wram_do,
 q    => sp_ram4_do
);

-- sprite line buffer 1
sprlinebuf1a : entity work.gen_ram
generic map( dWidth => 18, aWidth => 6)
port map(
 clk  => clock_vid,   -- ok
 we   => sp_buffer_ram1_we,
 addr => sp_buffer_ram1_addr,
 d    => sp_buffer_ram1_di,
 q    => sp_buffer_ram1_do
);

-- sprite line buffer 2
sprlinebuf2 : entity work.gen_ram
generic map( dWidth => 18, aWidth => 6)
port map(
 clk  => clock_vid,   -- ok
 we   => sp_buffer_ram2_we,
 addr => sp_buffer_ram2_addr,
 d    => sp_buffer_ram2_di,
 q    => sp_buffer_ram2_do
);

-- char graphics ROM 5N
--ch_graphics : entity work.popeye_ch_bits
--port map(
-- clk  => clock_vidn,
-- addr => ch_code_line,
-- data => ch_graphx_do
--);

ch_graphics : entity work.dpram
generic map( dWidth => 8, aWidth => 12)
port map(
 clk_a  => clock_vidn,
 addr_a => ch_code_line,
 q_a    => ch_graphx_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(11 downto 0),
 we_b   => ch_graphics_we,
 d_b    => dl_data
);

ch_graphics_we <= '1' when dl_wr = '1' and dl_addr(16 downto 12) = "10000" else '0'; -- 10000-10FFF

-- sprite graphics ROM 1E
--sprite_graphics1 : entity work.popeye_sp_bits_1
--port map(
-- clk  => clock_vidn,
-- addr => sp_code_line, 
-- data => sp_graphx1_do
--);

sprite_graphics1 : entity work.dpram
generic map( dWidth => 8, aWidth => 13)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_code_line,
 q_a    => sp_graphx1_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(12 downto 0),
 we_b   => sp_graphics1_we,
 d_b    => dl_data
);

sp_graphics1_we <= '1' when dl_wr = '1' and dl_addr(16 downto 13) = "0100" else '0'; -- 08000-09FFF
sp_graphics2_we <= '1' when dl_wr = '1' and dl_addr(16 downto 13) = "0101" else '0'; -- 0A000-0BFFF
sp_graphics3_we <= '1' when dl_wr = '1' and dl_addr(16 downto 13) = "0110" else '0'; -- 0C000-0DFFF
sp_graphics4_we <= '1' when dl_wr = '1' and dl_addr(16 downto 13) = "0111" else '0'; -- 0E000-0FFFF

-- sprite graphics ROM 1F
--sprite_graphics2 : entity work.popeye_sp_bits_2
--port map(
-- clk  => clock_vidn,
-- addr => sp_code_line, 
-- data => sp_graphx2_do
--);

sprite_graphics2 : entity work.dpram
generic map( dWidth => 8, aWidth => 13)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_code_line,
 q_a    => sp_graphx2_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(12 downto 0),
 we_b   => sp_graphics2_we,
 d_b    => dl_data
);

-- sprite graphics ROM 1J
--sprite_graphics3 : entity work.popeye_sp_bits_3
--port map(
-- clk  => clock_vidn,
-- addr => sp_code_line, 
-- data => sp_graphx3_do
--);

sprite_graphics3 : entity work.dpram
generic map( dWidth => 8, aWidth => 13)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_code_line,
 q_a    => sp_graphx3_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(12 downto 0),
 we_b   => sp_graphics3_we,
 d_b    => dl_data
);

-- sprite graphics ROM 1k
--sprite_graphics4 : entity work.popeye_sp_bits_4
--port map(
-- clk  => clock_vidn,
-- addr => sp_code_line, 
-- data => sp_graphx4_do
--);

sprite_graphics4 : entity work.dpram
generic map( dWidth => 8, aWidth => 13)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_code_line,
 q_a    => sp_graphx4_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(12 downto 0),
 we_b   => sp_graphics4_we,
 d_b    => dl_data
);

-- char palette
--ch_palette : entity work.popeye_ch_palette_rgb
--port map(
-- clk  => clock_vidn,
-- addr => ch_palette_addr,
-- data => ch_palette_do
--);

ch_palette : entity work.dpram
generic map( dWidth => 8, aWidth => 5)
port map(
 clk_a  => clock_vidn,
 addr_a => ch_palette_addr,
 q_a    => ch_palette_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(4 downto 0),
 we_b   => ch_palette_we,
 d_b    => dl_data
);
 
sp_palette1_we <= '1' when dl_wr = '1' and dl_addr(16 downto 8) = "100010000" else '0'; -- 11000-110FF
sp_palette2_we <= '1' when dl_wr = '1' and dl_addr(16 downto 8) = "100010001" else '0'; -- 11100-111FF
ch_palette_we  <= '1' when dl_wr = '1' and dl_addr(16 downto 5) = "100010010000" else '0'; -- 11200-1121F
bg_palette_we  <= '1' when dl_wr = '1' and dl_addr(16 downto 5) = "100010010001" else '0'; -- 11220-1123F
 
-- background palette
--bg_palette : entity work.popeye_bg_palette_rgb
--port map(
-- clk  => clock_vidn,
-- addr => bg_palette_addr,
-- data => bg_palette_do
--);

bg_palette : entity work.dpram
generic map( dWidth => 8, aWidth => 5)
port map(
 clk_a  => clock_vidn,
 addr_a => bg_palette_addr,
 q_a    => bg_palette_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(4 downto 0),
 we_b   => bg_palette_we,
 d_b    => dl_data
);


-- sprites palettes
--sp_palette_rg : entity work.popeye_sp_palette_rg
--port map(
-- clk  => clock_vidn,
-- addr => sp_palette_addr,
-- data => sp_palette_rg_do
--);

sp_palette_rg : entity work.dpram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_palette_addr,
 q_a    => sp_palette_rg_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(7 downto 0),
 we_b   => sp_palette1_we,
 d_b    => dl_data
);


--sp_palette_gb : entity work.popeye_sp_palette_gb
--port map(
-- clk  => clock_vidn,
-- addr => sp_palette_addr,
-- data => sp_palette_gb_do
--);

sp_palette_gb : entity work.dpram
generic map( dWidth => 8, aWidth => 8)
port map(
 clk_a  => clock_vidn,
 addr_a => sp_palette_addr,
 q_a    => sp_palette_gb_do,
 clk_b  => clock_vid,
 addr_b => dl_addr(7 downto 0),
 we_b   => sp_palette2_we,
 d_b    => dl_data
);


ym2149 : entity work.ym2149
port map (
-- data bus
	I_DA            => cpu_do,       --: in  std_logic_vector(7 downto 0);
	O_DA            => ay_do,        --: out std_logic_vector(7 downto 0);
	O_DA_OE_L       => open,         --: out std_logic;
-- control
	I_A9_L          => '0',          --: in  std_logic;
	I_A8            => '1',          --: in  std_logic;
	I_BDIR          => ay_bdir,      --: in  std_logic;
	I_BC2           => '1',          --: in  std_logic;
	I_BC1           => ay_bc1,       --: in  std_logic;
	I_SEL_L         => '1',          --: in  std_logic;
-- audio
	O_AUDIO         => ay_audio,     --: out std_logic_vector(7 downto 0);
-- port a
	I_IOA           => ay_ioa_di,    --: in  std_logic_vector(7 downto 0);
	O_IOA           => open,         --: out std_logic_vector(7 downto 0);
	O_IOA_OE_L      => open,         --: out std_logic;
-- port b
	I_IOB           => "11111111",   --: in  std_logic_vector(7 downto 0);
	O_IOB           => ay_iob_do,    --: out std_logic_vector(7 downto 0);
	O_IOB_OE_L      => open,         --: out std_logic;

	ENA             => ay_ena,       --: in  std_logic; -- clock enable for higher speed operation
	RESET_L         => '1',          --: in  std_logic;
	CLK             => clock_vid     --: in  std_logic  -- note 6 Mhz!
);

end struct;