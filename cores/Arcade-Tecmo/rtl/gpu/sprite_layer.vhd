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

use work.common.all;
use work.types.all;

-- The sprite layer is the part of the graphics pipeline that handles the
-- moving graphical elements you see on the screen.
--
-- They can be placed anywhere on the screen with per-pixel precision, can be
-- swapped about their horizontal and/or vertical axes, and can even overlap
-- each other.
--
-- There are four different sprite sizes – 8x8, 16x16, 32x32, and 64x64 – which
-- are all composed from one or more 8x8 tiles.
--
-- The data which describes the characteristics of each sprite — such as
-- position, size, etc. — is stored in the sprite RAM.
--
-- The pixel data for the 8x8 tiles which make up each sprite is stored in the
-- sprite tile ROM.
entity sprite_layer is
  generic (
    ROM_ADDR_WIDTH : natural;
    ROM_DATA_WIDTH : natural
  );
  port (
    -- reset
    reset : in std_logic;

    -- clock signals
    clk : in std_logic;
    cen : in std_logic;

    -- configuration
    config : in sprite_config_t;

    -- control signals
    busy : buffer std_logic;
    flip : in std_logic;

    -- sprite RAM
    ram_cs   : in std_logic;
    ram_we   : in std_logic;
    ram_addr : in unsigned(SPRITE_RAM_CPU_ADDR_WIDTH-1 downto 0);
    ram_din  : in byte_t;
    ram_dout : out byte_t;

    -- tile ROM
    rom_addr : out unsigned(ROM_ADDR_WIDTH-1 downto 0);
    rom_data : in std_logic_vector(ROM_DATA_WIDTH-1 downto 0);

    -- video signals
    video : in video_t;

    -- graphics data
    priority : out priority_t;
    data     : out byte_t
  );
end sprite_layer;

architecture arch of sprite_layer is
  -- the pixel offset of the sprite layer
  constant OFFSET : natural := 3;

  type state_t is (IDLE, LOAD, LATCH, BLIT, JUMP, DONE, SWAP);

  -- state signals
  signal state, next_state : state_t;

  signal ram_addr_b : unsigned(SPRITE_RAM_GPU_ADDR_WIDTH-1 downto 0) := (others => '0');
  signal ram_dout_b : std_logic_vector(SPRITE_RAM_GPU_DATA_WIDTH-1 downto 0);

  signal ram_cs_rising : std_logic;

  -- frame buffer
  signal frame_buffer_swap   : std_logic;
  signal frame_buffer_addr_a : unsigned(FRAME_BUFFER_ADDR_WIDTH-1 downto 0);
  signal frame_buffer_din_a  : std_logic_vector(FRAME_BUFFER_DATA_WIDTH-1 downto 0);
  signal frame_buffer_we_a   : std_logic;
  signal frame_buffer_addr_b : unsigned(FRAME_BUFFER_ADDR_WIDTH-1 downto 0);
  signal frame_buffer_dout_b : std_logic_vector(FRAME_BUFFER_DATA_WIDTH-1 downto 0);
  signal frame_buffer_re_b   : std_logic;

  -- sprite counter
  subtype sprite_counter_type is natural range 0 to 255;
  signal sprite_counter : sprite_counter_type;

  -- sprite descriptor
  signal sprite : sprite_t;

  -- logical position
  signal logical_pos : pos_t;

  -- control signals
  signal frame_done    : std_logic;
  signal blitter_start : std_logic;
  signal blitter_ready : std_logic;
begin
  -- The sprite RAM (2kB) contains the sprite data.
  sprite_ram : entity work.true_dual_port_ram
  generic map (
    ADDR_WIDTH_A => SPRITE_RAM_CPU_ADDR_WIDTH,
    ADDR_WIDTH_B => SPRITE_RAM_GPU_ADDR_WIDTH,
    DATA_WIDTH_B => SPRITE_RAM_GPU_DATA_WIDTH
  )
  port map (
    -- CPU interface
    clk_a  => clk,
    cs_a   => ram_cs,
    we_a   => ram_we and not busy,
    addr_a => ram_addr,
    din_a  => ram_din,
    dout_a => ram_dout,

    -- GPU interface
    clk_b  => clk,
    addr_b => ram_addr_b,
    dout_b => ram_dout_b
  );

  sprite_frame_buffer : entity work.frame_buffer
  generic map (
    ADDR_WIDTH => FRAME_BUFFER_ADDR_WIDTH,
    DATA_WIDTH => FRAME_BUFFER_DATA_WIDTH
  )
  port map (
    clk  => clk,

    swap => frame_buffer_swap,

    -- port A (write)
    addr_a => frame_buffer_addr_a,
    din_a  => frame_buffer_din_a,
    we_a   => frame_buffer_we_a,

    -- port B (read)
    addr_b => frame_buffer_addr_b,
    dout_b => frame_buffer_dout_b,
    re_b   => frame_buffer_re_b
  );

  sprite_biltter : entity work.sprite_blitter
  port map (
    clk => clk,
    cen => cen,

    sprite => sprite,

    -- control signals
    ready => blitter_ready,
    start => blitter_start,

    -- sprite ROM
    rom_addr => rom_addr,
    rom_data => rom_data,

    -- frame buffer
    frame_buffer_addr => frame_buffer_addr_a,
    frame_buffer_data => frame_buffer_din_a,
    frame_buffer_we   => frame_buffer_we_a
  );

  -- detect rising edges of the RAM_CS signal
  ram_cs_edge_detector : entity work.edge_detector
  generic map (RISING => true)
  port map (
    clk  => clk,
    data => ram_cs,
    q    => ram_cs_rising
  );

  -- state machine
  fsm : process (state, video.vblank, blitter_ready, frame_done)
  begin
    next_state <= state;

    case state is
      -- this is the default state, we just wait for the beginning of the frame
      when IDLE =>
        if video.vblank = '0' then
          next_state <= LOAD;
        end if;

      -- load the sprite
      when LOAD =>
        next_state <= LATCH;

      -- latch the sprite
      when LATCH =>
        next_state <= BLIT;

      -- blit the sprite
      when BLIT =>
        if blitter_ready = '1' then
          next_state <= JUMP;
        end if;

      -- check whether the frame is done
      when JUMP =>
        if frame_done = '1' then
          next_state <= DONE;
        else
          next_state <= LOAD;
        end if;

      -- wait for the end of the frame
      when DONE =>
        if video.vblank = '1' then
          next_state <= SWAP;
        end if;

      -- swap the frame buffer
      when SWAP =>
        next_state <= IDLE;
    end case;
  end process;

  -- latch the next state
  latch_next_state : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        state <= next_state;
      end if;
    end if;
  end process;

  -- Update the sprite counter.
  --
  -- Sprites are sorted from lowest to highest priority. If sprites are
  -- overlapping, then the higher priority sprites will appear above lower
  -- priority sprites.
  update_sprite_counter : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        if state = JUMP then
          sprite_counter <= sprite_counter + 1;
        end if;
      end if;
    end if;
  end process;

  -- latch sprite from the sprite RAM
  latch_sprite : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        if state = LATCH then
          sprite <= decode_sprite(config, ram_dout_b);
        end if;
      end if;
    end if;
  end process;

  -- start a blit operation
  blit_sprite : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        if state = LOAD then
          blitter_start <= '1';
        else
          blitter_start <= '0';
        end if;
      end if;
    end if;
  end process;

  -- swap the frame buffer page
  swap_frame_buffer : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        if state = SWAP then
          frame_buffer_swap <= not frame_buffer_swap;
        end if;
      end if;
    end if;
  end process;

  -- latch graphics data from the frame buffer
  latch_gfx_data : process (clk)
  begin
    if rising_edge(clk) then
      if cen = '1' then
        priority <= frame_buffer_dout_b(9 downto 8);
        data     <= frame_buffer_dout_b(7 downto 0);
      end if;
    end if;
  end process;

  -- The busy signal is asserted when the CPU tries to access the VRAM. It is
  -- deasserted after the tile data has been latched.
  latch_busy : process (clk, reset)
  begin
    if reset = '1' then
      busy <= '0';
    elsif rising_edge(clk) then
      if cen = '1' then
        if state = LATCH then
          busy <= '0';
        elsif ram_cs_rising = '1' then
          busy <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Set the logical postion
  --
  -- The video position is inverted when the screen is flipped.
  logical_pos.x <= ('0' & not video.pos.x(7 downto 0))-OFFSET when flip = '1' else
                   ('0' & video.pos.x(7 downto 0))+OFFSET;
  logical_pos.y <= ('0' & not video.pos.y(7 downto 0)) when flip = '1' else
                   ('0' & video.pos.y(7 downto 0));

  -- set sprite RAM address
  ram_addr_b <= to_unsigned(sprite_counter, ram_addr_b'length);

  -- the frame is done when all the sprites have been blitted
  frame_done <= '1' when sprite_counter = sprite_counter_type'high else '0';

  -- load graphics data from the frame buffer
  frame_buffer_addr_b <= logical_pos.y(7 downto 0) & logical_pos.x(7 downto 0);

  -- enable reading from the frame buffer when video output is enabled
  frame_buffer_re_b <= cen and video.enable;
end architecture arch;
