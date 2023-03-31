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
from litex.build.generic_platform import *
from litex_boards.platforms import terasic_deca
from litex.gen import LiteXModule

from litex.soc.cores.clock import Max10PLL

from util import *

# CRG ----------------------------------------------------------------------------------------------

# TODO: currently unused, replace top PLL
class _CRG(Module):
    def __init__(self, platform):
        self.rst      = ResetSignal()
        self.cd_sys   = ClockDomain()
        self.cd_spi   = ClockDomain()

        # Clk / Rst
        clk50 = platform.request("clk50")

        # PLL
        pll = Max10PLL(speedgrade="-6")
        self.submodules += pll
        self.comb += pll.reset.eq(self.rst)
        pll.register_clkin(clk50, 50e6)
        pll.create_clkout(self.cd_sys, 50e6)
        pll.create_clkout(self.cd_spi, 100e6)

# Build --------------------------------------------------------------------------------------------

class Top(LiteXModule):
    def __init__(self, platform) -> None:
        sdram       = platform.request("sdram")
        hdmi        = platform.request("hdmi")
        hdmi_i2c    = platform.request("hdmi_i2c")
        hdmi_i2s    = platform.request("hdmi_i2s")
        sdcard      = platform.request("sdcard")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")

        crg = _CRG(platform)
        self.submodules += crg

        sys_top = Instance("sys_top",
            i_CLK_50   = crg.cd_sys.clk,
            i_clk_100m = crg.cd_spi.clk,

            # HDMI I2C
            o_HDMI_I2C_SCL  = hdmi_i2c.scl,
            io_HDMI_I2C_SDA = hdmi_i2c.sda,            
            # HDMI I2S
            o_HDMI_MCLK     = hdmi_i2s.mclk,
            o_HDMI_SCLK     = hdmi_i2s.sclk,
            o_HDMI_LRCLK    = hdmi_i2s.lrclk,
            o_HDMI_I2S      = hdmi_i2s.i2s,
            # HDMI VIDEO
            o_HDMI_TX_D     = Cat(hdmi.b, hdmi.g, hdmi.r),
            o_HDMI_TX_CLK   = hdmi.clk,
            o_HDMI_TX_DE    = hdmi.de,
            o_HDMI_TX_HS    = hdmi.hsync,
            o_HDMI_TX_VS    = hdmi.vsync,
            i_HDMI_TX_INT   = hdmi.int,

            # SDRAM
            o_SDRAM_A      = sdram.a,
            io_SDRAM_DQ    = sdram.dq,
            # o_SDRAM_DQML = sdram.dm[0], not connected
            # o_SDRAM_DQMH = sdram.dm[1], not connected
            o_SDRAM_nWE    = sdram.we_n,
            o_SDRAM_nCAS   = sdram.cas_n,
            o_SDRAM_nRAS   = sdram.ras_n,
            o_SDRAM_nCS    = sdram.cs_n,
            o_SDRAM_BA     = sdram.ba,
            o_SDRAM_CLK    = platform.request("sdram_clock"),
            # o_SDRAM_CKE  = sdram.cke, not connected

            # TODO: DAC
            # o_AUDIO_L     = audio.l,
            # o_AUDIO_R     = audio.r,
            # o_AUDIO_SPDIF = audio.spdif,
            # io_SDCD_SPDIF = audio.sbcd_spdif,

            o_LED_USER  = platform.request("user_led", 0),
            o_LED_HDD   = platform.request("user_led", 1),
            o_LED_POWER = platform.request("user_led", 2),
            # i_BTN_USER  = platform.request("user_btn", 0),
            i_BTN_OSD   = platform.request("user_btn", 0),
            i_BTN_RESET = platform.request("user_btn", 1),

            o_SD_SPI_CS   = sdcard.sel,
            i_SD_SPI_MISO = sdcard.data[0],
            o_SD_SPI_CLK  = sdcard.clk,
            o_SD_SPI_MOSI = sdcard.cmd,

            o_LED = Cat([platform.request("user_led", led) for led in range(3, 5)]),

            i_HPS_SPI_MOSI = hps_spi.mosi,
            o_HPS_SPI_MISO = hps_spi.miso,
            i_HPS_SPI_CLK = hps_spi.clk,
            i_HPS_SPI_CS = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE = hps_control.osd_enable,
            i_HPS_IO_ENABLE = hps_control.io_enable,
            i_HPS_CORE_RESET = hps_control.core_reset,
            # o_DEBUG = N/C
        )

        self.specials += sys_top

def main(core):
    coredir = join("cores", core)

    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = terasic_deca.Platform()

    add_designfiles(platform, coredir, mistex_yaml, 'quartus')

    generate_build_id(platform, coredir)
    add_mainfile(platform, coredir, mistex_yaml)

    defines = mistex_yaml.get('defines', {})
    defines.update({
        "ALTERA": 1,
        "MAX10":  1,
        "MISTER_DOWNSCALE_NN": 1,
        # "MISTER_DISABLE_ADAPTIVE": 1,
        # "MISTER_SMALL_VBUF": 1,
        "MISTER_DISABLE_YC": 1,
        "MISTER_DISABLE_ALSA": 1,
    })

    for key, value in defines.items():
        platform.add_platform_command(f'set_global_assignment -name VERILOG_MACRO "{key}={value}"')

    platform.add_extension([
        ("hps_spi", 0,
            Subsignal("mosi", Pins("P9:23")),
            Subsignal("miso", Pins("P9:24")),
            Subsignal("clk",  Pins("P9:22")),
            Subsignal("cs_n", Pins("P9:21")),
            IOStandard("3.3-V LVTTL"),
        ),
        ("hps_control", 0,
            Subsignal("fpga_enable", Pins("P9:18")),
            Subsignal("osd_enable",  Pins("P9:19")),
            Subsignal("io_enable",   Pins("P9:20")),
            Subsignal("core_reset",  Pins("P9:17")),
            IOStandard("3.3-V LVTTL"),
        ),
        ("sdram_clock", 0, Pins("P8:22"), IOStandard("3.3-V LVTTL")),
        ("sdram", 0,
            Subsignal("a",     Pins(
                "P8:39 P8:40 P8:41 P8:42 P8:30 P8:27 P8:28 P8:25", 
                "P8:26 P8:23 P8:38 P8:24 P8:21")),
            Subsignal("ba",    Pins("P8:36 P8:37")),
            Subsignal("cs_n",  Pins("P8:35")),
            #Subsignal("cke",   Pins("N/C")), 
            Subsignal("ras_n", Pins("P8:34")),
            Subsignal("cas_n", Pins("P8:33")),
            Subsignal("we_n",  Pins("P8:29")),
            Subsignal("dq", Pins(
                "P8:3  P8:4  P8:5  P8:6  P8:7  P8:8  P8:9  P8:10 ",
                "P8:20 P8:19 P8:18 P8:17 P8:16 P8:15 P8:12 P8:11")),
            #Subsignal("dm", Pins("N/C")),
            IOStandard("3.3-V LVTTL")
        ),
    ])

    platform.build(Top(platform),
        build_dir     = get_build_dir(core),
        build_name    = core.replace("-", "_"))

if __name__ == "__main__":
    handle_main(main)
