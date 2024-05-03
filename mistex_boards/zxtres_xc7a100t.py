#!/usr/bin/env python3
#
# This file is part of MiSTeX-Boards.
#
# Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause
#

from os.path import join
import sys
import yaml

from colorama import Fore, Style

from migen import *
from migen.genlib.misc import WaitTimer
from migen.genlib.cdc import MultiReg
from litex.gen.fhdl.module import LiteXModule
from litex.build.generic_platform import *
from platforms import zxtres_artix7_fgg484

from litex.soc.cores.spi.spi_bone import SPIBone
from litex.soc.cores.clock import S7PLL, S7IDELAYCTRL, S7MMCM
from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import *

from util import *

# CRG ----------------------------------------------------------------------------------------------

class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq):
        self.rst          = Signal()
        self.cd_sys       = ClockDomain()
        self.cd_sys4x     = ClockDomain()
        self.cd_sys4x_dqs = ClockDomain()
        self.cd_idelay    = ClockDomain()
        self.cd_retro     = ClockDomain()
        self.cd_retro2x   = ClockDomain()
        self.cd_video     = ClockDomain()
        self.cd_emu_ddram = ClockDomain()
        self.cd_hdmi      = ClockDomain()
        self.cd_hdmi5x    = ClockDomain()

        clk_in            = platform.request("clk50")

        self.pll = pll = S7PLL(speedgrade=-1)
        try:
            reset_button = platform.request("cpu_reset")
            self.comb += pll.reset.eq(~reset_button | self.rst)
        except:
            self.comb += pll.reset.eq(self.rst)

        pll.register_clkin(clk_in,            50e6)
        pll.create_clkout (self.cd_sys,       sys_clk_freq)
        pll.create_clkout (self.cd_sys4x,     4*sys_clk_freq)
        pll.create_clkout (self.cd_sys4x_dqs, 4*sys_clk_freq, phase=90)
        pll.create_clkout (self.cd_idelay,    200e6)
        pll.create_clkout (self.cd_retro,     50e6)
        pll.create_clkout (self.cd_retro2x,   100e6)

        self.hdmipll = hdmipll = S7PLL(speedgrade=-1)
        hdmipll.register_clkin(clk_in,          50e6)
        hdmipll.create_clkout(self.cd_hdmi,     74.25e6)
        hdmipll.create_clkout(self.cd_hdmi5x, 5*74.25e6)

        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin)
        platform.add_false_path_constraints(self.cd_retro2x.clk, pll.clkin)
        platform.add_false_path_constraints(self.cd_sys.clk, hdmipll.clkin)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_hdmi.clk)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_retro.clk)
        
        self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)


# LiteX SoC to initialize DDR3 ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, core_name, toolchain="vivado", **kwargs):
        sys_clk_freq=125e6
        self.debug = True

        # CRG --------------------------------------------------------------------------------------
        self.crg = _CRG(platform, sys_clk_freq)
        self.platform = platform

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["uart_name"]            = "jtag_uart"           #serial
        #kwargs["uart_baudrate"]        = 500e3
        kwargs["cpu_type"]             = "None"
        kwargs["l2_size"]              = 0
        kwargs["bus_data_width"]       = 32
        kwargs["bus_address_width"]    = 32
        kwargs['integrated_rom_size']  = 0
        kwargs['integrated_sram_size'] = 0
        SoCCore.__init__(self, platform, sys_clk_freq, ident = f"{core_name} LiteX SoC on MiSTeX ZXTRES XC7A100T", **kwargs)


        self.gamecore = Gamecore(platform, self, sys_clk_freq)

        # if self.debug:
        #     # SPIBone ----------------------------------------------------------------------------------
        #     self.submodules.spibone = spibone = SPIBone(platform.request("spibone"))
        #     self.add_wb_master(spibone.bus)
        #     #self.add_uartbone(name="serial", clk_freq=sys_clk_freq, baudrate=115200) #baudrate=500000)


# MiSTeX core --------------------------------------------------------------------------------------------

# class Top(LiteXModule):
class Gamecore(Module):
    def __init__(self, platform, soc, sys_clk_freq) -> None:
        sdram       = platform.request("sdram")
        vga         = platform.request("vga")
        sdcard      = platform.request("sdcard")
        audio       = platform.request("audio")
        # I2s audio                                     # TODO
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")
        # debug       = platform.request("debug")

        sys_top = Instance("sys_top",
            i_CLK_50        = ClockSignal("retro"),
            i_CLK_100       = ClockSignal("retro2x"),
            o_CLK_VIDEO     = ClockSignal("video"),

            # TODO: DISPLAYPORT

            o_SDRAM_A = sdram.a,
            io_SDRAM_DQ = sdram.dq,
            o_SDRAM_DQML = sdram.dm[0],
            o_SDRAM_DQMH = sdram.dm[1],
            o_SDRAM_nWE = sdram.we_n,
            o_SDRAM_nCAS = sdram.cas_n,
            o_SDRAM_nRAS = sdram.ras_n,
            o_SDRAM_nCS = sdram.cs_n,
            o_SDRAM_BA = sdram.ba,
            o_SDRAM_CLK = platform.request("sdram_clock"),
            o_SDRAM_CKE = sdram.cke,

            o_VGA_R = Cat([s for s in (vga.r)]),
            o_VGA_G = Cat([s for s in (vga.g)]),
            o_VGA_B = Cat([s for s in (vga.b)]),
            io_VGA_HS = vga.hsync_n,
            o_VGA_VS = vga.vsync_n,

            o_AUDIO_L = audio.l,
            o_AUDIO_R = audio.r,
            # o_AUDIO_SPDIF = NC

            o_LED_USER  = platform.request("user_led", 0),
            o_LED_HDD   = platform.request("user_led", 1),
            # o_LED_POWER = NC
            # i_BTN_USER  = NC
            # i_BTN_OSD   = NC
            # i_BTN_RESET = NC

            o_SD_SPI_CS   = sdcard.cs,
            i_SD_SPI_MISO = sdcard.miso,
            o_SD_SPI_CLK  = sdcard.clk,
            o_SD_SPI_MOSI = sdcard.mosi,

            # io_SDCD_SPDIF = NC

            i_HPS_SPI_MOSI = hps_spi.mosi,
            o_HPS_SPI_MISO = hps_spi.miso,
            i_HPS_SPI_CLK  = hps_spi.clk,
            i_HPS_SPI_CS   = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE  = hps_control.osd_enable,
            i_HPS_IO_ENABLE   = hps_control.io_enable,
            i_HPS_CORE_RESET  = hps_control.core_reset,

            # o_DEBUG = debug,
        )

        self.specials += sys_top

def main(coredir, core):

    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = zxtres_artix7_fgg484.Platform(with_daughterboard=True, kgates=100)

    add_designfiles(platform, coredir, mistex_yaml, 'vivado')

    defines = [
        ('XILINX', 1),
        ('LARGE_FPGA', 1),
        # ('MISTEX_HDMI', 1),

        # ('DEBUG_HPS_OP', 1),

        # On Xilinx we need this to get a proper clock tree
        ('CLK_100_EXT', 1),

        # do not enable DEBUG_NOHDMI in release!
        ('MISTER_DEBUG_NOHDMI', 1),

        # disable bilinear filtering when downscaling
        ('MISTER_DOWNSCALE_NN', 1),

        # disable adaptive scanline filtering
        #('MISTER_DISABLE_ADAPTIVE', 1),

        # use only 1MB per frame for scaler to free ~21MB DDR3 RAM
        #('MISTER_SMALL_VBUF', 1),

        # Disable YC / Composite output to save some resources
        ('MISTER_DISABLE_YC', 1),

        # Disable ALSA audio output to save some resources
        ('MISTER_DISABLE_ALSA', 1),

        # Speed up compilation, disable audio filter
        ('SKIP_IIR_FILTER', 1),
    ]

    for key, value in mistex_yaml.get('defines', {}).items():
        defines.append((key, value))

    build_id_path = generate_build_id(platform, coredir, defines)
    platform.toolchain.pre_synthesis_commands += [
        f'set_property is_global_include true [get_files "../../../{build_id_path}"]',
        'set_property default_lib work [current_project]'
    ]

    add_mainfile(platform, coredir, mistex_yaml)


    platform.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {{hps_spi_clk_IBUF}}]")
    platform.add_extension([
        ("audio", 0,
            Subsignal("l",          Pins("V19")),
            Subsignal("r",          Pins("U17")),
            IOStandard("LVCMOS33")
        ),

        # I2s audio                     # TODO

        ("sdcard", 0,
            Subsignal("clk",  Pins("M6")),
            Subsignal("mosi",  Pins("L4")),
            Subsignal("miso", Pins("M5")),
            Subsignal("cs",   Pins("L5")),
            IOStandard("LVCMOS33")
        ),

        # MiSTeX middleboard adapter
        ("hps_spi", 0,
            Subsignal("cs_n", Pins("W9")),
            Subsignal("mosi", Pins("W6")),    # exchange with W6
            Subsignal("miso", Pins("W5")),    
            Subsignal("clk",  Pins("W4")),    # need to be W4 for a fast capable pin MRCC (SRCC 2nd option)
            IOStandard("LVCMOS33"),
        ),
        ("hps_control", 0,
            Subsignal("core_reset",  Pins("W7")), 
            Subsignal("fpga_enable", Pins("J2")), 
            Subsignal("osd_enable",  Pins("V7")), 
            Subsignal("io_enable",   Pins("V8")), 
            IOStandard("LVCMOS33"),
        ),

        # VGA video
        ("vga", 0,
            Subsignal("hsync_n", Pins("V18")),
            Subsignal("vsync_n", Pins("P19")),
            Subsignal("r", Pins("P20 Y19 V20 AB20 AA19 W17")),  # LSB R6 T5
            Subsignal("g", Pins("V17 W20 AB22 Y22 AA21 W22")),  # LSB V5 V4 
            Subsignal("b", Pins("T20 AB21 Y21 AA20 W19 W21")),  # LSB T6 U5 
            IOStandard("LVCMOS33")
        ),

        # ("spibone", 0, 
        #     Subsignal("clk",  Pins("J1:11")),
        #     Subsignal("mosi", Pins("J1:13")),
        #     Subsignal("miso", Pins("J1:15")),
        #     Subsignal("cs_n", Pins("J1:17")),
        #     IOStandard("LVCMOS33")),
    ])

    build_dir = get_build_dir(core)

    soc = BaseSoC(platform, core_name=core)
    builder = Builder(soc,
        build_backend="litex",
        gateware_dir=build_dir,
        software_dir=os.path.join(build_dir, 'software'),
        compile_gateware=True,
        compile_software=True,
        csr_csv="csr.csv",
        bios_console="lite"
    )

    builder.build(build_name = get_build_name(core))

if __name__ == "__main__":
    handle_main(main)
