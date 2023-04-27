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

# Build --------------------------------------------------------------------------------------------

class Top(LiteXModule):
    def __init__(self, platform) -> None:
        sdram       = platform.request("sdram")
        vga         = platform.request("vga")
        ddram       = platform.request("ddram")
   #    hps_i2c     = platform.request("hps_i2c")
        hdmi        = platform.request("hdmi")
        hdmi_i2c    = platform.request("hdmi_i2c")
        hdmi_i2s    = platform.request("hdmi_i2s")
        sdcard      = platform.request("sdcard")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")

        leds = Signal(8)
        self.comb += Cat([platform.request("user_led", l) for l in range(8)]).eq(~leds)

        clk50 = Signal()
        self.comb += clk50.eq(platform.request("clk50"))

        AW = 26
        DW = 64

        avalon_clock         = Signal()
        avalon_address       = Signal(AW)
        avalon_byteenable    = Signal(DW//8)
        avalon_read          = Signal()
        avalon_readdata      = Signal(DW)
        avalon_burstcount    = Signal(8)
        avalon_write         = Signal()
        avalon_writedata     = Signal(DW)
        avalon_ready         = Signal()
        avalon_readdatavalid = Signal()
        avalon_burstbegin    = Signal()
        avalon_waitrequest   = Signal()

        afi_half_clk = Signal()
        afi_reset_export_n = Signal()
        afi_reset_n = Signal()

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

        ddr3 = Instance("ddr3",
            i_pll_ref_clk         = clk50,
            i_global_reset_n      = ~ResetSignal(),
            i_soft_reset_n        = ~ResetSignal(),
            o_afi_clk             = avalon_clock,
            o_afi_half_clk        = afi_half_clk,
            o_afi_reset_n         = afi_reset_export_n,
            o_afi_reset_export_n  = afi_reset_n,

            o_mem_a               = ddram.a,
            o_mem_ba              = ddram.ba,
            io_mem_ck             = ddram.clk_p,
            io_mem_ck_n           = ddram.clk_n,
            o_mem_cke             = ddram.cke,
            o_mem_cs_n            = ddram.cs_n,
            o_mem_dm              = ddram.dm,
            o_mem_ras_n           = ddram.ras_n,
            o_mem_cas_n           = ddram.cas_n,
            o_mem_we_n            = ddram.we_n,
            o_mem_reset_n         = ddram.reset_n,
            io_mem_dq             = ddram.dq,
            io_mem_dqs            = ddram.dqs_p,
            io_mem_dqs_n          = ddram.dqs_n,
            o_mem_odt             = ddram.odt,

            o_avl_ready           = avalon_ready,
            i_avl_burstbegin      = avalon_burstbegin,
            i_avl_addr            = avalon_address,
            o_avl_rdata_valid     = avalon_readdatavalid,
            o_avl_rdata           = avalon_readdata,
            i_avl_wdata           = avalon_writedata,
            i_avl_be              = avalon_byteenable,
            i_avl_read_req        = avalon_read,
            i_avl_write_req       = avalon_write,
            i_avl_size            = avalon_burstcount,
            o_local_init_done     = leds[5],
            o_local_cal_success   = leds[6],
            o_local_cal_fail      = leds[7],
            # o_pll_mem_clk         = 
            # o_pll_write_clk       = 
            o_pll_locked          = leds[4],
            # o_pll_capture0_clk    = 
            # o_pll_capture1_clk    = 
        )
        self.specials += ddr3

        self.comb += [
            avalon_burstbegin.eq(avalon_write & avalon_read),
            avalon_waitrequest.eq(~avalon_ready),
        ]

        sys_top = Instance("sys_top",
            p_DW            = DW,
            p_AW            = AW,
            i_CLK_50        = clk50,

            # HDMI I2C
            o_HDMI_I2C_SCL  = hdmi_i2c.scl,
            io_HDMI_I2C_SDA = hdmi_i2c.sda,            
            # HDMI I2S
            o_HDMI_MCLK     = hdmi_i2s.mclk,
            o_HDMI_SCLK     = hdmi_i2s.sclk,
            o_HDMI_LRCLK    = hdmi_i2s.lrclk,
            o_HDMI_I2S      = hdmi_i2s.i2s,
            # HDMI VIDEO
            o_HDMI_TX_D     = Cat(hdmi.r, hdmi.g, hdmi.b),
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

            o_SD_SPI_CS   = sdcard.sel,
            i_SD_SPI_MISO = sdcard.data[0],
            o_SD_SPI_CLK  = sdcard.clk,
            o_SD_SPI_MOSI = sdcard.cmd,

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

            i_ddr3_clk_i           = avalon_clock,
            o_ddr3_address_o       = avalon_address,
            o_ddr3_byteenable_o    = avalon_byteenable,
            o_ddr3_read_o          = avalon_read,
            i_ddr3_readdata_i      = avalon_readdata,
            o_ddr3_burstcount_o    = avalon_burstcount,
            o_ddr3_write_o         = avalon_write,
            o_ddr3_writedata_o     = avalon_writedata,
            i_ddr3_waitrequest_i   = avalon_waitrequest,
            i_ddr3_readdatavalid_i = avalon_readdatavalid,
        )
        self.specials += sys_top

def main(core):
    coredir = join("cores", core)

    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = terasic_deca.Platform()

    add_designfiles(platform, coredir, mistex_yaml, 'quartus')

    generate_build_id(platform, coredir)
    add_mainfile(platform, coredir, mistex_yaml)

    platform.add_platform_command(f"set_global_assignment -name QIP_FILE {os.getcwd()}/rtl/deca-ddr3/ddr3.qip")
    platform.add_platform_command("set_global_assignment -name AUTO_RAM_TO_LCELL_CONVERSION ON")

    defines = mistex_yaml.get('defines', {})
    defines.update({
        "ALTERA": 1,
        "CRG_AUDIO_CLK": 1,
        "HARDWARE_HDMI_INIT": 1,
        #"NO_SCANDOUBLER": 1,
        #"DISBALE_VGA": 1,
        # "SKIP_ASCAL": 1,
        # "MISTER_DISABLE_ADAPTIVE": 1,
        # "MISTER_SMALL_VBUF": 1,
        "MISTER_DISABLE_YC": 1,
        "MISTER_DISABLE_ALSA": 1,
    })

    for key, value in defines.items():
        platform.add_platform_command(f'set_global_assignment -name VERILOG_MACRO "{key}={value}"')

    platform.add_extension([
        #("hps_i2c", 0,
        #    Subsignal("sda", Pins("N/C")),
        #    Subsignal("scl", Pins("N/C")),
        #    IOStandard("3.3-V LVTTL"),
        #),
        ("vga", 0,
            Subsignal("hsync_n", Pins("P9:14")),
            Subsignal("vsync_n", Pins("P9:13")),
            Subsignal("r", Pins("P9:16 P9:26 P9:24 P9:22")),
            Subsignal("g", Pins("P9:17 P9:20 P9:19 P9:18")),
            Subsignal("b", Pins("P9:15 P9:25 P9:23 P9:21")),
            IOStandard("3.3-V LVTTL")
        ),
        ("hps_spi", 0,
            Subsignal("mosi", Pins("P9:30")),
            Subsignal("miso", Pins("P9:29")),
            Subsignal("clk",  Pins("P9:31")),
            Subsignal("cs_n", Pins("P8:5")),
            IOStandard("3.3-V LVTTL"),
        ),
        ("hps_control", 0,
            Subsignal("fpga_enable", Pins("P8:3")),
            Subsignal("osd_enable",  Pins("P8:6")),
            Subsignal("io_enable",   Pins("P9:42")),
            Subsignal("core_reset",  Pins("P8:4")),
            IOStandard("3.3-V LVTTL"),
        ),
        ("sdram_clock", 0, Pins("P8:26"), IOStandard("3.3-V LVTTL")),
        ("sdram", 0,
            Subsignal("a",     Pins(
                "P8:43 P8:44 P8:45 P8:46 P8:34 P8:31 P8:32 P8:29", 
                "P8:30 P8:27 P8:42 P8:28 P8:25")),
            Subsignal("ba",    Pins("P8:40 P8:41")),
            Subsignal("cs_n",  Pins("P8:39")),
            Subsignal("cke",   Pins("P8:36")), 
            Subsignal("ras_n", Pins("P8:38")),
            Subsignal("cas_n", Pins("P8:37")),
            Subsignal("we_n",  Pins("P8:33")),
            Subsignal("dq", Pins(
                "P8:7  P8:8  P8:9  P8:10  P8:11  P8:12  P8:13  P8:14 ",
                "P8:24 P8:23 P8:22 P8:21 P8:20 P8:19 P8:16 P8:15")),
            Subsignal("dm", Pins("P8:17 P8:18")),
            IOStandard("3.3-V LVTTL")
        ),
    ])

    build_dir  = get_build_dir(core)
    build_name = core.replace("-", "_")
    platform.build(Top(platform),
        build_dir  = build_dir,
        build_name = build_name)

    os.system(f"quartus_cpf -c -q 24.0MHz -g 3.3 -n p {build_dir}/{build_name}.sof {build_dir}/{build_name}.svf")
    #https://github.com/opengateware-labs/tools-max10_svf_cleaner
    os.system(f"max10_svf_cleaner {build_dir}/{build_name}.svf")

if __name__ == "__main__":
    handle_main(main)
