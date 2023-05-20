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
from litex.gen import Open
from litex.gen.fhdl.module import LiteXModule
from litex.build.generic_platform import *
from litex_boards.platforms import qmtech_artix7_fbg484

from litex.soc.cores.spi.spi_bone import SPIBone
from litex.soc.cores.clock import S7PLL, S7IDELAYCTRL, S7MMCM
from litex.soc.cores.video import VideoS7HDMIPHY
from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import *
from litex.soc.interconnect.avalon import AvalonMMInterface

from litedram.modules import MT41J128M16
from litedram.phy import s7ddrphy
from litedram.frontend.avalon import LiteDRAMAvalonMM2Native


from util import *

# CRG ----------------------------------------------------------------------------------------------

class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq, with_ethernet=False):
        self.rst          = Signal()
        self.cd_sys       = ClockDomain()
        self.cd_sys4x     = ClockDomain()
        self.cd_sys4x_dqs = ClockDomain()
        self.cd_idelay    = ClockDomain()
        self.cd_retro     = ClockDomain()
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

        self.hdmipll = hdmipll = S7PLL(speedgrade=-1)
        hdmipll.register_clkin(clk_in,            50e6)
        hdmipll.create_clkout(self.cd_hdmi,       74.25e6)
        hdmipll.create_clkout(self.cd_hdmi5x,     5*74.25e6)

        if with_ethernet:
            self.cd_eth = ClockDomain()
            self.ethpll = ethpll = S7PLL(speedgrade=-1)
            ethpll.register_clkin(ClockSignal("sys"), sys_clk_freq)
            ethpll.create_clkout(self.cd_eth, 25e6)

        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_sys.clk, hdmipll.clkin)

        self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

# LiteX SoC to initialize DDR3 ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, toolchain="vivado", kgates=200, sys_clk_freq=100e6,  **kwargs):
        self.debug = True

        # CRG --------------------------------------------------------------------------------------
        self.crg = _CRG(platform, sys_clk_freq, with_ethernet=False)
        self.platform = platform

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["uart_name"]            = "serial"
        kwargs["uart_baudrate"]        = 500e3
        kwargs["cpu_type"]             = "serv"
        kwargs["l2_size"]              = 0
        kwargs["bus_data_width"]       = 32
        kwargs["bus_address_width"]    = 32
        kwargs['integrated_rom_size']  = 0x8000
        kwargs['integrated_sram_size'] = 0x1000
        SoCCore.__init__(self, platform, sys_clk_freq, ident = f"LiteX SoC on MiSTeX QMTech XC7A200T", **kwargs)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        self.ddrphy = s7ddrphy.A7DDRPHY(platform.request("ddram"),
            memtype        = "DDR3",
            nphases        = 4,
            sys_clk_freq   = sys_clk_freq)
        self.add_sdram("sdram",
            phy           = self.ddrphy,
            module        = MT41J128M16(sys_clk_freq, "1:4"),
            l2_cache_size = 0)
        self.add_constant("SDRAM_TEST_DISABLE")

        self.gamecore = Gamecore(platform, self, sys_clk_freq)

        if self.debug:
            # SPIBone ----------------------------------------------------------------------------------
            self.submodules.spibone = spibone = SPIBone(platform.request("spibone"))
            self.add_wb_master(spibone.bus)
            #self.add_uartbone(name="serial", clk_freq=sys_clk_freq, baudrate=115200) #baudrate=500000)

            from litescope import LiteScopeAnalyzer
            analyzer_signals = [
                # DBus (could also just added as self.cpu.dbus)
                self.gamecore.avalon.address,
                self.gamecore.avalon.waitrequest,
                self.gamecore.avalon.read,
                self.gamecore.avalon.readdata,
                self.gamecore.avalon.readdatavalid,
                self.gamecore.avalon.write,
                self.gamecore.avalon.writedata,
                self.gamecore.avalon.burstcount,
                self.gamecore.avalon.byteenable,
                #self.gamecore.videophy.sink.valid,
                #self.gamecore.videophy.sink.ready,
                #self.gamecore.videophy.sink.de,
                #self.gamecore.videophy.sink.hsync,
                #self.gamecore.videophy.sink.vsync,
            ]
            self.analyzer = LiteScopeAnalyzer(analyzer_signals,
                depth        = 2048,
                samplerate   = sys_clk_freq,
                clock_domain = "sys",
                csr_csv      = "analyzer.csv")


# MiSTeX core --------------------------------------------------------------------------------------------

class Gamecore(Module):
    def __init__(self, platform, soc, sys_clk_freq) -> None:
        vga         = platform.request("vga")
        sdcard      = platform.request("sdcard")
        seven_seg   = platform.request("seven_seg")
        audio       = platform.request("audio")
        hdmi        = platform.request("hdmi")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")
        debug       = platform.request("debug")

        # ascal can't take more than 28 bits of address width
        avalon_data_width = 64
        avalon_address_width = 28

        sdram_port = soc.sdram.crossbar.get_port(data_width=avalon_data_width)
        self.avalon = avalon = AvalonMMInterface(data_width=avalon_data_width, adr_width=avalon_address_width)
        self.submodules.avalon_port = LiteDRAMAvalonMM2Native(avalon, sdram_port)

        self.submodules.videophy = videophy = VideoS7HDMIPHY(hdmi, clock_domain="hdmi", flip_diff_pairs=True)
        video = videophy.sink
        self.comb += video.valid.eq(1)

        self.submodules.avalon_start_delay = start_delay = WaitTimer(int(6*sys_clk_freq))
        self.comb += start_delay.wait.eq(~ResetSignal())

        avalon_read  = Signal()
        avalon_write = Signal()

        self.comb += [
            avalon.read .eq(Mux(start_delay.done, avalon_read,  0)),
            avalon.write.eq(Mux(start_delay.done, avalon_write, 0)),
        ]

        sys_top = Instance("sys_top",
            p_DW = avalon_data_width,
            p_AW = avalon_address_width,
            p_ASCAL_RAMBASE = 0x0,

            i_CLK_50   = ClockSignal("retro"),
            i_CLK_100  = ClockSignal("sys"),

            # TODO: HDMI
            #o_HDMI_I2C_SCL,
            #io_HDMI_I2C_SDA,
            #
            #o_HDMI_MCLK,
            #o_HDMI_SCLK,
            #o_HDMI_LRCLK,
            #o_HDMI_I2S,
            #
            #o_HDMI_TX_CLK  = ,
            o_HDMI_TX_DE  = video.de,
            o_HDMI_TX_D   = Cat(video.b, video.g, video.r),
            o_HDMI_TX_HS  = video.hsync,
            o_HDMI_TX_VS  = video.vsync,
            i_HDMI_CLK_IN = ClockSignal("hdmi"),
            # i_HDMI_TX_INT

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

            i_ddr3_clk_i           = ClockSignal("sys"),
            o_ddr3_address_o       = avalon.address,
            o_ddr3_byteenable_o    = avalon.byteenable,
            o_ddr3_read_o          = avalon_read,
            i_ddr3_readdata_i      = avalon.readdata,
            o_ddr3_burstcount_o    = avalon.burstcount,
            o_ddr3_write_o         = avalon_write,
            o_ddr3_writedata_o     = avalon.writedata,
            i_ddr3_waitrequest_i   = Mux(start_delay.done, avalon.waitrequest, 1),
            i_ddr3_readdatavalid_i = Mux(start_delay.done, avalon.readdatavalid, 0),
        )

        self.specials += sys_top

def main(core):
    coredir = join("cores", core)

    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = qmtech_artix7_fbg484.Platform(with_daughterboard=True)

    add_designfiles(platform, coredir, mistex_yaml, 'vivado')

    defines = [
        ('XILINX', 1),
        ('LARGE_FPGA', 1),
        ('MISTEX_HDMI', 1),

        # ('DEBUG_HPS_OP', 1),

        # On Xilinx we need this to get a proper clock tree
        ('CLK_100_EXT', 1),

        # do not enable DEBUG_NOHDMI in release!
        # ('MISTER_DEBUG_NOHDMI', 1),

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

    platform.add_extension([
        ("audio", 0,
            Subsignal("spdif",      Pins("J1:5")),
            Subsignal("sbcd_spdif", Pins("J1:7")),
            Subsignal("l",          Pins("J1:6")),
            Subsignal("r",          Pins("J1:8")),
            IOStandard("LVCMOS33")
        ),

        # MiSTeX Pmod on pmoda
        ("hps_spi", 0,
            Subsignal("cs_n", Pins("pmoda:0")),
            Subsignal("mosi", Pins("pmoda:1")),
            Subsignal("miso", Pins("pmoda:2")),
            Subsignal("clk",  Pins("pmoda:3")),
            IOStandard("LVCMOS33"),
        ),
        ("hps_control", 0,
            Subsignal("core_reset",  Pins("pmoda:4")),
            Subsignal("fpga_enable", Pins("pmoda:5")),
            Subsignal("osd_enable",  Pins("pmoda:6")),
            Subsignal("io_enable",   Pins("pmoda:7")),
            IOStandard("LVCMOS33"),
        ),

        # HDMI Pmod
        ("hdmi", 0,
            Subsignal("clk_p",   Pins("pmodb:7"),   IOStandard("TMDS_33")),
            Subsignal("clk_n",   Pins("pmodb:3"),   IOStandard("TMDS_33")),
            Subsignal("data0_p", Pins("pmodb:6"),   IOStandard("TMDS_33")),
            Subsignal("data0_n", Pins("pmodb:2"),   IOStandard("TMDS_33")),
            Subsignal("data1_p", Pins("pmodb:5"),   IOStandard("TMDS_33")),
            Subsignal("data1_n", Pins("pmodb:1"),   IOStandard("TMDS_33")),
            Subsignal("data2_p", Pins("pmodb:4"),   IOStandard("TMDS_33")),
            Subsignal("data2_n", Pins("pmodb:0"),   IOStandard("TMDS_33")),
        ),

        ("debug", 0, Pins("J1:18 J1:16 J1:14 J1:12"),
            IOStandard("LVCMOS33")),
        ("spibone", 0, 
            Subsignal("clk",  Pins("J1:11")),
            Subsignal("mosi", Pins("J1:13")),
            Subsignal("miso", Pins("J1:15")),
            Subsignal("cs_n", Pins("J1:17")),
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
        csr_csv="csr.csv",
        bios_console="lite")
    builder.build(build_name = get_build_name(core))

if __name__ == "__main__":
    handle_main(main)
