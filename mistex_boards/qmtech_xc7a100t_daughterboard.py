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
from litex_boards.platforms import qmtech_artix7_fgg676

from litex.soc.cores.spi.spi_bone import SPIBone
from litex.soc.cores.clock import S7PLL, S7IDELAYCTRL, S7MMCM
from litex.soc.cores.video import VideoS7HDMIPHY
from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import *
from litex.soc.interconnect.avalon import AvalonMMInterface

from litedram.modules import MT41J128M16
from litedram.phy import s7ddrphy
from litedram.common import PHYPadsReducer
from litedram.core.controller import ControllerSettings
from litedram.frontend.avalon import LiteDRAMAvalonMM2Native

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
        #hdmipll.create_clkout(self.cd_hdmi5x, 5*74.25e6)

        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_retro2x.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_sys.clk, hdmipll.clkin)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_hdmi.clk)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_retro.clk)

        self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

# LiteX SoC to initialize DDR3 ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, core_name, toolchain="vivado", delay_hps_miso=0, **kwargs):
        sys_clk_freq=125e6
        self.debug = True

        # CRG --------------------------------------------------------------------------------------
        self.crg = _CRG(platform, sys_clk_freq)
        self.platform = platform

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["uart_name"]            = "serial"
        kwargs["uart_baudrate"]        = 500e3
        kwargs["cpu_type"]             = "femtorv"
        kwargs["l2_size"]              = 0
        kwargs["bus_data_width"]       = 32
        kwargs["bus_address_width"]    = 32
        kwargs['integrated_rom_size']  = 0x8000
        kwargs['integrated_sram_size'] = 0x1000
        SoCCore.__init__(self, platform, sys_clk_freq, ident = f"{core_name} LiteX SoC on MiSTeX QMTech XC7A100T", **kwargs)

        # DDR3 SDRAM -------------------------------------------------------------------------------
        self.ddrphy = s7ddrphy.A7DDRPHY(
            # Two chips do not work at 125MHz
            # But 125MB is still plenty for us
            PHYPadsReducer(platform.request("ddram"), [0]),
            memtype        = "DDR3",
            nphases        = 4,
            sys_clk_freq   = sys_clk_freq)
        self.add_sdram("sdram",
            phy           = self.ddrphy,
            module        = MT41J128M16(sys_clk_freq, "1:4"),
            l2_cache_size = 0,
            controller_settings=ControllerSettings(with_auto_precharge=False))
        #self.add_constant("SDRAM_TEST_DISABLE")

        self.gamecore = Gamecore(platform, self, sys_clk_freq, delay_hps_miso)

        # need this to put it into analyzer
        the_emu_ddram_clk = Signal()
        self.comb += the_emu_ddram_clk.eq(ClockSignal("emu_ddram"))

        if self.debug:
            # SPIBone ----------------------------------------------------------------------------------
            self.submodules.spibone = spibone = SPIBone(platform.request("spibone"))
            self.add_wb_master(spibone.bus)
            #self.add_uartbone(name="serial", clk_freq=sys_clk_freq, baudrate=115200) #baudrate=500000)

            from litescope import LiteScopeAnalyzer
            analyzer_signals = [
                # DBus (could also just added as self.cpu.dbus)
                self.gamecore.scaler_ddram.address,
                self.gamecore.scaler_ddram.waitrequest,
                self.gamecore.scaler_ddram.read,
                #self.gamecore.scaler_ddram.readdata,
                self.gamecore.scaler_ddram.readdatavalid,
                self.gamecore.scaler_ddram.write,
                #self.gamecore.scaler_ddram.writedata,
                self.gamecore.scaler_ddram.burstcount,

                the_emu_ddram_clk,
                self.gamecore.emu_ddram.address,
                self.gamecore.emu_ddram.waitrequest,
                self.gamecore.emu_ddram.read,
                #self.gamecore.emu_ddram.readdata,
                self.gamecore.emu_ddram.readdatavalid,
                self.gamecore.emu_ddram.write,
                #self.gamecore.emu_ddram.writedata,
                self.gamecore.emu_ddram.burstcount,

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
    def __init__(self, platform, soc, sys_clk_freq, delay_hps_miso) -> None:
        vga         = platform.request("vga")
        sdcard      = platform.request("sdcard")
        seven_seg   = platform.request("seven_seg")
        audio       = platform.request("audio")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")
        debug       = platform.request("debug")

        # ascal can't take more than 28 bits of address width
        avalon_data_width = 64
        avalon_address_width = 28

        scaler_ddram_port  = soc.sdram.crossbar.get_port(data_width=avalon_data_width)
        self.scaler_ddram = scaler_ddram   = AvalonMMInterface(data_width=avalon_data_width, adr_width=avalon_address_width)
        self.submodules.scaler_avalon_port = LiteDRAMAvalonMM2Native(scaler_ddram, scaler_ddram_port)

        emu_ddram_port = soc.sdram.crossbar.get_port(data_width=avalon_data_width, clock_domain="emu_ddram")
        self.emu_ddram = emu_ddram      = AvalonMMInterface(data_width=avalon_data_width, adr_width=avalon_address_width)
        self.submodules.emu_avalon_port = ClockDomainsRenamer("emu_ddram")(LiteDRAMAvalonMM2Native(emu_ddram, emu_ddram_port))

        self.submodules.avalon_start_delay = start_delay = WaitTimer(int(3*sys_clk_freq))
        self.comb += start_delay.wait.eq(~ResetSignal())

        scaler_avalon_read  = Signal()
        scaler_avalon_write = Signal()
        emu_avalon_read     = Signal()
        emu_avalon_write    = Signal()

        self.comb += [
            scaler_ddram.read .eq(Mux(start_delay.done, scaler_avalon_read,  0)),
            scaler_ddram.write.eq(Mux(start_delay.done, scaler_avalon_write, 0)),
            emu_ddram .read .eq(Mux(start_delay.done, emu_avalon_read,  0)),
            emu_ddram .write.eq(Mux(start_delay.done, emu_avalon_write, 0)),
        ]

        # on most cores the MISO signal is pretty much 1 bit too slow,
        # which we compensate for on the HPS by shifting the received SPI word
        # but not for the menu core, for some reason (TODO: find out why)
        hps_miso = Signal()
        if 0 < delay_hps_miso:
            self.specials += MultiReg(i=hps_miso, o=hps_spi.miso, odomain="retro", n=delay_hps_miso)
        else:
            self.comb += hps_spi.miso.eq(hps_miso)

        sys_top = Instance("sys_top",
            p_DW = avalon_data_width,
            p_AW = avalon_address_width,
            p_ASCAL_RAMBASE = 0x2000000,

            i_CLK_50        = ClockSignal("retro"),
            i_CLK_100       = ClockSignal("retro2x"),
            o_CLK_VIDEO     = ClockSignal("video"),
            o_CLK_EMU_DDRAM = ClockSignal("emu_ddram"),

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
            # o_HDMI_TX_DE  = video.de,
            # o_HDMI_TX_D   = Cat(video.b, video.g, video.r),
            # o_HDMI_TX_HS  = video.hsync,
            # o_HDMI_TX_VS  = video.vsync,
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
            o_HPS_SPI_MISO = hps_miso,
            i_HPS_SPI_CLK  = hps_spi.clk,
            i_HPS_SPI_CS   = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE  = hps_control.osd_enable,
            i_HPS_IO_ENABLE   = hps_control.io_enable,
            i_HPS_CORE_RESET  = hps_control.core_reset,

            o_DEBUG = debug,

            i_ddr3_clk_i           = ClockSignal("sys"),
            o_ddr3_address_o       = scaler_ddram.address,
            o_ddr3_byteenable_o    = scaler_ddram.byteenable,
            o_ddr3_read_o          = scaler_avalon_read,
            i_ddr3_readdata_i      = scaler_ddram.readdata,
            o_ddr3_burstcount_o    = scaler_ddram.burstcount,
            o_ddr3_write_o         = scaler_avalon_write,
            o_ddr3_writedata_o     = scaler_ddram.writedata,
            i_ddr3_waitrequest_i   = Mux(start_delay.done, scaler_ddram.waitrequest, 1),
            i_ddr3_readdatavalid_i = Mux(start_delay.done, scaler_ddram.readdatavalid, 0),

            o_ram_address_o       = emu_ddram.address,
            o_ram_byteenable_o    = emu_ddram.byteenable,
            o_ram_read_o          = emu_avalon_read,
            i_ram_readdata_i      = emu_ddram.readdata,
            o_ram_burstcount_o    = emu_ddram.burstcount,
            o_ram_write_o         = emu_avalon_write,
            o_ram_writedata_o     = emu_ddram.writedata,
            i_ram_waitrequest_i   = Mux(start_delay.done, emu_ddram.waitrequest, 1),
            i_ram_readdatavalid_i = Mux(start_delay.done, emu_ddram.readdatavalid, 0),
        )

        self.specials += sys_top

def main(coredir, core):
    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    platform = qmtech_artix7_fgg676.Platform(with_daughterboard=True)

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
            Subsignal("spdif",      Pins("J1:6")),
            Subsignal("sbcd_spdif", Pins("J1:8")),
            Subsignal("l",          Pins("J1:5")),
            Subsignal("r",          Pins("J1:7")),
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

    delay_hps_miso = mistex_yaml.get('delay-hps-miso', 0)
    soc = BaseSoC(platform, core_name=core, delay_hps_miso=delay_hps_miso)
    builder = Builder(soc,
        build_backend="litex",
        gateware_dir=build_dir,
        software_dir=os.path.join(build_dir, 'software'),
        compile_gateware=True,
        compile_software=True,
        csr_csv="csr.csv",
        #bios_console="lite"
    )

    builder.build(build_name = get_build_name(core))

if __name__ == "__main__":
    handle_main(main)
