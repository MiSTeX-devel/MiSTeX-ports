#!/usr/bin/env python3
#
# This file is part of MiSTeX-Boards.
#
# Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause
#
# DE10_lite JP3 (Arduino connector 1x18 pins) is used for RPI_zero I/F
# DE10_lite JP1 (GPIO connector    2x20 pins) is kept free for RAM extension
# 
# Signal       FPGA   DE10lite JP3     RPI_Zero
# name         pin    Arduino conn.    gpio conn.
#                        name           pin  name
# core_reset   AB5       IO0            15   gpio22
# fpga_enable  AB6       IO1            16   gpio23
# osd_enable   AB7       IO2            18   gpio24
# io_enable    AB8       IO3            22   gpio25
# mosi         AB19      IO4            19   spi0_mosi
# miso         Y10       IO5            21   spi0_miso
# clk          AA11      IO6            23   spi0_sclk
# cs_n         AA12      IO7            24   spi0_ce0_n 
# GND                    GND            14   ground 
 
# sound_pwm_r            IO8 (reserved for future use) 
# sound_pwm_l            IO9 (reserved for future use) 

 
from os.path import join
import sys
import yaml

from colorama import Fore, Style

from migen import *
from litex.build.generic_platform import *
from litex_boards.platforms import terasic_de10lite
from litex.gen import LiteXModule

from litex.soc.cores.clock import Max10PLL

from util import *

# Build --------------------------------------------------------------------------------------------

class Top(LiteXModule):
    def __init__(self, platform) -> None:
        sdram       = platform.request("sdram")
        vga         = platform.request("vga")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")

        leds = Signal(9)
        self.comb += Cat([platform.request("user_led", l) for l in range(9)]).eq(~leds)

        clk50 = Signal()
        self.comb += clk50.eq(platform.request("clk50"))

        AW = 26
        DW = 64

        if False:
            i2c_repeater = Instance("i2crepeater",
                 i_reset             = ResetSignal(),
                 i_system_clk        = crg.cd_sys.clk,
                 i_master_scl        = hps_i2c.scl,
                 io_master_sda       = hps_i2c.sda,
                 o_slave_scl         = hdmi_i2c.scl,
                 io_slave_sda        = hdmi_i2c.sda,
            )
            self.specials += i2c_repeater
        else:
            pass

        sys_top = Instance("sys_top",
            p_DW            = DW,
            p_AW            = AW,
            i_CLK_50        = clk50,

            # SDRAM
            o_SDRAM_A      = sdram.a,
            io_SDRAM_DQ    = sdram.dq,
            o_SDRAM_DQML = sdram.dm[0],
            o_SDRAM_DQMH = sdram.dm[1],
            o_SDRAM_nWE    = sdram.we_n,
            o_SDRAM_nCAS   = sdram.cas_n,
            o_SDRAM_nRAS   = sdram.ras_n,
            o_SDRAM_nCS    = sdram.cs_n,
            o_SDRAM_BA     = sdram.ba,
            o_SDRAM_CLK    = platform.request("sdram_clock"),
            o_SDRAM_CKE  = sdram.cke,

            o_VGA_R = Cat(False, False, [s for s in (vga.r)]),
            o_VGA_G = Cat(False, False, [s for s in (vga.g)]),
            o_VGA_B = Cat(False, False, [s for s in (vga.b)]),
            io_VGA_HS = vga.hsync_n,
            o_VGA_VS = vga.vsync_n,

            # TODO: DAC
            # o_AUDIO_L     = audio.l,
            # o_AUDIO_R     = audio.r,
            # o_AUDIO_SPDIF = audio.spdif,
            # io_SDCD_SPDIF = audio.sbcd_spdif,

            o_LED_USER  = leds[2],
            o_LED_HDD   = leds[1],
            o_LED_POWER = leds[0],
            # i_BTN_USER  = platform.request("user_btn", 0),
            i_BTN_OSD   = platform.request("user_btn", 0),
            i_BTN_RESET = platform.request("user_btn", 1),

            #o_LED = Cat([leds[l]) for led in range(3, 5)]),

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

def main(coredir, core):

    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = terasic_de10lite.Platform()

    build_dir  = get_build_dir(core)
    build_name = core.replace("-", "_")
    add_designfiles(platform, coredir, mistex_yaml, 'quartus', build_dir)

    generate_build_id(platform, coredir)
    add_mainfile(platform, coredir, mistex_yaml)

    defines = mistex_yaml.get('defines', {})
    defines.update({
        "ALTERA": 1,
        "CRG_AUDIO_CLK": 1,
        # "HARDWARE_HDMI_INIT": 1,
        # "NO_SCANDOUBLER": 1,
        # "DISABLE_VGA": 1,
        "SKIP_ASCAL": 1,
        # "MISTER_DISABLE_ADAPTIVE": 1,
        # "MISTER_SMALL_VBUF": 1,
        "MISTER_DEBUG_NOHDMI": 1,
        "SKIP_ASCAL": 1,
        "NO_DDRAM": 1,
        "MISTER_DISABLE_YC": 1,
        "MISTER_DISABLE_ALSA": 1,
    })

    for key, value in defines.items():
        platform.add_platform_command(f'set_global_assignment -name VERILOG_MACRO "{key}={value}"')

    platform.add_extension([
        ("hps_spi", 0,
            Subsignal("mosi", Pins("AB9")),
            Subsignal("miso", Pins("Y10")),
            Subsignal("clk",  Pins("AA11")),
            Subsignal("cs_n", Pins("AA12")),
            IOStandard("3.3-V LVTTL"),
        ),
        ("hps_control", 0,
            Subsignal("fpga_enable", Pins("AB6")),
            Subsignal("osd_enable",  Pins("AB7")),
            Subsignal("io_enable",   Pins("AB8")),
            Subsignal("core_reset",  Pins("AB5")),
            IOStandard("3.3-V LVTTL"),
        ),
    ])

    platform.build(Top(platform),
        build_dir  = build_dir,
        build_name = build_name)

    os.system(f"quartus_cpf -c -q 24.0MHz -g 3.3 -n p {build_dir}/{build_name}.sof {build_dir}/{build_name}.svf")
    #https://github.com/opengateware-labs/tools-max10_svf_cleaner
    os.system(f"max10_svf_cleaner {build_dir}/{build_name}.svf")

if __name__ == "__main__":
    handle_main(main)
