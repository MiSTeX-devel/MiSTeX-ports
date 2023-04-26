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
from litex.gen.fhdl.module import LiteXModule
from litex.build.generic_platform import *
from litex_boards.platforms import qmtech_artix7_fgg676

from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import *
from litex.soc.cores.clock import S7PLL, S7IDELAYCTRL
from litex.soc.interconnect import wishbone
from litedram.modules import MT41J128M16
from litedram.phy import s7ddrphy

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

        clk_in            = platform.request("clk50")
        # # #

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
        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.

        self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

# LiteX SoC to initialize DDR3 ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, toolchain="vivado", kgates=100, sys_clk_freq=100e6,  **kwargs):
        # CRG --------------------------------------------------------------------------------------
        self.crg = _CRG(platform, sys_clk_freq)
        self.platform = platform

        DW = 128

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["uart_name"]            = "serial"
        kwargs["cpu_type"]             = "serv"
        kwargs["l2_size"]              = 0
        kwargs["bus_data_width"]       = DW
        kwargs["bus_address_width"]    = 32
        kwargs['integrated_rom_size']  = 0x8000
        kwargs['integrated_sram_size'] = 0x1000
        SoCCore.__init__(self, platform, sys_clk_freq, ident = f"LiteX SoC on MiSTeX QMTech XC7A100T", **kwargs)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        self.ddrphy = s7ddrphy.A7DDRPHY(platform.request("ddram"),
            memtype        = "DDR3",
            nphases        = 4,
            sys_clk_freq   = sys_clk_freq)
        self.add_sdram("sdram",
            phy           = self.ddrphy,
            module        = MT41J128M16(sys_clk_freq, "1:4"),
            l2_cache_size = 0)

        self.gamecore = Gamecore(platform, self, DW)


# MiSTeX core --------------------------------------------------------------------------------------------

class Gamecore(Module):
    def __init__(self, platform, soc, DW) -> None:
        #sdram       = platform.request("sdram")
        vga         = platform.request("vga")
        sdcard      = platform.request("sdcard")
        seven_seg   = platform.request("seven_seg")
        audio       = platform.request("audio")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")
        debug       = platform.request("debug")

        AW = 28

        soc_bone = wishbone.Interface(data_width=DW, adr_width=AW)
        soc.bus.add_master("mistex", soc_bone)

        avalon_address       = Signal(AW)
        avalon_byteenable    = Signal(DW//8)
        avalon_read          = Signal()
        avalon_readdata      = Signal(DW)
        avalon_burstcount    = Signal(8)
        avalon_write         = Signal()
        avalon_writedata     = Signal(DW)
        avalon_waitrequest   = Signal()
        avalon_readdatavalid = Signal()

        self.specials += Instance("avalon_to_wb_bridge",
            i_wb_clk_i = ClockSignal("sys"),
            i_wb_rst_i = ResetSignal("sys"),

            # avalon
            i_s_av_address_i       = avalon_address,
            i_s_av_byteenable_i    = avalon_byteenable,
            i_s_av_read_i          = avalon_read,
            o_s_av_readdata_o      = avalon_readdata,
            i_s_av_burstcount_i    = avalon_burstcount,
            i_s_av_write_i         = avalon_write,
            i_s_av_writedata_i     = avalon_writedata,
            o_s_av_waitrequest_o   = avalon_waitrequest,
            o_s_av_readdatavalid_o = avalon_readdatavalid,

            # wishbone
            o_wbm_adr_o = soc_bone.adr,
            o_wbm_dat_o = soc_bone.dat_w,
            o_wbm_sel_o = soc_bone.sel,
            o_wbm_we_o  = soc_bone.we,
            o_wbm_cyc_o = soc_bone.cyc,
            o_wbm_stb_o = soc_bone.stb,
            o_wbm_cti_o = soc_bone.cti,
            o_wbm_bte_o = soc_bone.bte,
            i_wbm_dat_i = soc_bone.dat_r,
            i_wbm_ack_i = soc_bone.ack,
            i_wbm_err_i = soc_bone.err,
        )

        sys_top = Instance("sys_top",
            p_DW = DW,
            p_AW = AW,

            i_CLK_50   = ClockSignal("retro"),
            i_clk_100m = ClockSignal("sys"),

            # TODO: HDMI
            #o_HDMI_I2C_SCL,
            #io_HDMI_I2C_SDA,
            #
            #o_HDMI_MCLK,
            #o_HDMI_SCLK,
            #o_HDMI_LRCLK,
            #o_HDMI_I2S,
            #
            #o_HDMI_TX_CLK,
            #o_HDMI_TX_DE,
            #o_HDMI_TX_D,
            #o_HDMI_TX_HS,
            #o_HDMI_TX_VS,
            #i_HDMI_TX_INT,

            #o_SDRAM_A = sdram.a,
            #io_SDRAM_DQ = sdram.dq,
            #o_SDRAM_DQML = sdram.dm[0],
            #o_SDRAM_DQMH = sdram.dm[1],
            #o_SDRAM_nWE = sdram.we_n,
            #o_SDRAM_nCAS = sdram.cas_n,
            #o_SDRAM_nRAS = sdram.ras_n,
            #o_SDRAM_nCS = sdram.cs_n,
            #o_SDRAM_BA = sdram.ba,
            #o_SDRAM_CLK = platform.request("sdram_clock"),
            #o_SDRAM_CKE = sdram.cke,

            o_VGA_R = Cat(False, [s for s in reversed(vga.r)]),
            o_VGA_G = Cat(       [s for s in reversed(vga.g)]),
            o_VGA_B = Cat(False, [s for s in reversed(vga.b)]),
            io_VGA_HS = vga.hsync_n,
            o_VGA_VS = vga.vsync_n,

            o_AUDIO_L = audio.l,
            o_AUDIO_R = audio.r,
            o_AUDIO_SPDIF = audio.spdif,

            o_LED_USER  = platform.request("user_led", 0),
            o_LED_HDD   = platform.request("user_led", 1),
            o_LED_POWER = platform.request("user_led", 2),
            i_BTN_USER  = platform.request("user_btn", 0),
            i_BTN_OSD   = platform.request("user_btn", 1),
            i_BTN_RESET = platform.request("user_btn", 2),

            o_SD_SPI_CS   = sdcard.cd,
            i_SD_SPI_MISO = sdcard.data[0],
            o_SD_SPI_CLK  = sdcard.clk,
            o_SD_SPI_MOSI = sdcard.cmd,

            io_SDCD_SPDIF = audio.sbcd_spdif,

            o_LED = seven_seg,

            i_HPS_SPI_MOSI = hps_spi.mosi,
            o_HPS_SPI_MISO = hps_spi.miso,
            i_HPS_SPI_CLK  = hps_spi.clk,
            i_HPS_SPI_CS   = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE  = hps_control.osd_enable,
            i_HPS_IO_ENABLE   = hps_control.io_enable,
            i_HPS_CORE_RESET  = hps_control.core_reset,

            o_DEBUG = debug,

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

    platform = qmtech_artix7_fgg676.Platform(with_daughterboard=True)

    add_designfiles(platform, coredir, mistex_yaml, 'vivado')
    platform.add_source("rtl/avalon_to_wb_bridge.v")

    defines = [
        ('XILINX', 1),
        # ('LARGE_FPGA', 1),

        # ('DEBUG_HPS_OP', 1),

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
    ]

    for key, value in mistex_yaml.get('defines', {}).items():
        defines.append((key, value))

    build_id_path = generate_build_id(platform, coredir, defines)
    platform.toolchain.pre_synthesis_commands += [
        f'set_property is_global_include true [get_files "../../../{build_id_path}"]',
        'set_property default_lib work [current_project]'
    ]

    # TODO
    # platform.add_platform_command('set_false_path -from [get_clocks clk_sys] -to [get_clocks clk_audio]')

    add_mainfile(platform, coredir, mistex_yaml)

    platform.add_extension([
        ("audio", 0,
            Subsignal("l",          Pins("pmoda:0")),
            Subsignal("r",          Pins("pmoda:1")),
            Subsignal("spdif",      Pins("pmoda:2")),
            Subsignal("sbcd_spdif", Pins("pmoda:3")),
            IOStandard("LVCMOS33")
        ),
        ("hps_spi", 0,
            Subsignal("mosi", Pins("pmodb:0")),
            Subsignal("miso", Pins("pmodb:1")),
            Subsignal("clk",  Pins("pmodb:2")),
            Subsignal("cs_n", Pins("pmodb:3")),
            IOStandard("LVCMOS33"),
        ),
        ("hps_control", 0,
            Subsignal("fpga_enable", Pins("pmodb:4")),
            Subsignal("osd_enable",  Pins("pmodb:5")),
            Subsignal("io_enable",   Pins("pmodb:6")),
            Subsignal("core_reset",  Pins("pmodb:7")),
            IOStandard("LVCMOS33"),
        ),
        ("debug", 0, Pins("J1:18 J1:16 J1:14 J1:12"),
                     IOStandard("LVCMOS33")),
    ])

    build_dir = get_build_dir(core)

    soc = BaseSoC(platform)
    builder = Builder(soc,
        build_backend="litex",
        gateware_dir=build_dir,
        software_dir=os.path.join(build_dir, 'software'),
        compile_gateware=True,
        compile_software=True,
        bios_console="lite")
    builder.build(build_name  = core.replace("-", "_"))

if __name__ == "__main__":
    handle_main(main)
