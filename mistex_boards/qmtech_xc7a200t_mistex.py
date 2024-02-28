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
from litex_boards.platforms import qmtech_artix7_fbg484

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
from mistex_boards.qmtex_mistex import extension

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

        self.hdmipll = hdmipll = S7MMCM(speedgrade=-1)
        hdmipll.register_clkin(clk_in,          50e6)
        hdmipll.create_clkout(self.cd_hdmi,     74.25e6)

        platform.add_false_path_constraints(self.cd_sys.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_retro2x.clk, pll.clkin) # Ignore sys_clk to pll.clkin path created by SoC's rst.
        platform.add_false_path_constraints(self.cd_sys.clk, hdmipll.clkin)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_hdmi.clk)
        platform.add_false_path_constraints(self.cd_sys.clk, self.cd_retro.clk)

        self.idelayctrl = S7IDELAYCTRL(self.cd_idelay)

# LiteX SoC to initialize DDR3 ------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, core_name, toolchain, **kwargs):
        sys_clk_freq=125e6
        self.debug = False

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

        self.gamecore = Gamecore(platform, self, sys_clk_freq)

        # need this to put it into analyzer
        the_emu_ddram_clk = Signal()
        self.comb += the_emu_ddram_clk.eq(ClockSignal("emu_ddram"))

# MiSTeX core --------------------------------------------------------------------------------------------

class Gamecore(Module):
    def __init__(self, platform, soc, sys_clk_freq) -> None:
        led         = platform.request("led")
        button      = platform.request("button")
        rgb         = platform.request("rgb")
        i2c         = platform.request("i2c")
        i2s         = platform.request("i2s")
        sdcard      = platform.request("sdcard")
        sdram       = platform.request("sdram")
        audio       = platform.request("audio")
        snac        = platform.request("snac")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")

        if soc.debug:
            # SPIBone ----------------------------------------------------------------------------------
            self.submodules.spibone = spibone = SPIBone(platform.request("spibone"))
            self.add_wb_master(spibone.bus)

            from litescope import LiteScopeAnalyzer
            analyzer_signals = [
            ]
            self.analyzer = LiteScopeAnalyzer(analyzer_signals,
                depth        = 2048,
                samplerate   = sys_clk_freq,
                clock_domain = "sys",
                csr_csv      = "analyzer.csv")

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

        sys_top = Instance("sys_top",
            p_DW = avalon_data_width,
            p_AW = avalon_address_width,
            p_ASCAL_RAMBASE = 0x2000000,

            i_CLK_50        = ClockSignal("retro"),
            i_CLK_100       = ClockSignal("retro2x"),
            o_CLK_VIDEO     = ClockSignal("video"),
            o_CLK_EMU_DDRAM = ClockSignal("emu_ddram"),

            # Let the HPS do the I2C
            # o_HDMI_I2C_SCL  = i2c.scl,
            # io_HDMI_I2C_SDA = i2c.sda,

            # I2S
            o_HDMI_MCLK   = i2s.mclk  if not soc.debug else None,
            o_HDMI_SCLK   = i2s.sclk  if not soc.debug else None,
            o_HDMI_LRCLK  = i2s.lrclk if not soc.debug else None,
            o_HDMI_I2S    = i2s.dat   if not soc.debug else None,

            #
            o_HDMI_TX_CLK = rgb.clk,
            o_HDMI_TX_DE  = rgb.de,
            o_HDMI_TX_D   = rgb.d,
            o_HDMI_TX_HS  = rgb.hsync,
            o_HDMI_TX_VS  = rgb.vsync,
            i_HDMI_TX_INT = rgb.int,
            i_HDMI_CLK_IN = ClockSignal("hdmi"),

            o_SDRAM_A    = sdram.a,
            io_SDRAM_DQ  = sdram.dq,
            o_SDRAM_nWE  = sdram.we_n,
            o_SDRAM_nCAS = sdram.cas_n,
            o_SDRAM_nRAS = sdram.ras_n,
            o_SDRAM_nCS  = sdram.cs_n,
            o_SDRAM_BA   = sdram.ba,
            o_SDRAM_CLK  = sdram.clk,

            # o_VGA_R   # NC
            # o_VGA_G   # NC
            # o_VGA_B   # NC
            # io_VGA_HS # NC
            # o_VGA_VS  # NC

            o_AUDIO_L = audio.l,
            o_AUDIO_R = audio.r,
            o_AUDIO_SPDIF = audio.spdif,

            o_LED_USER  = led.user,
            o_LED_HDD   = led.hdd,
            o_LED_POWER = led.power,
            # i_BTN_USER  # connected to HPS
            # i_BTN_OSD   # connected to HPS
            # i_BTN_RESET # connected to HPS

            o_SD_SPI_CS   = sdcard.data[3],
            i_SD_SPI_MISO = sdcard.data[0],
            o_SD_SPI_CLK  = sdcard.clk,
            o_SD_SPI_MOSI = sdcard.cmd,

            # io_SDCD_SPDIF # NC

            # o_LED # NC

            io_USER_IO = snac.user,

            i_HPS_SPI_MOSI = hps_spi.mosi,
            o_HPS_SPI_MISO = hps_spi.miso,
            i_HPS_SPI_CLK  = hps_spi.clk,
            i_HPS_SPI_CS   = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE  = hps_control.osd_enable,
            i_HPS_IO_ENABLE   = hps_control.io_enable,
            i_HPS_CORE_RESET  = hps_control.core_reset,

            #o_DEBUG = debug,

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

    toolchain = os.environ.get('MISTEX_TOOLCHAIN')
    if toolchain is None:
        toolchain = "vivado"
    platform = qmtech_artix7_fbg484.Platform(with_daughterboard=False, toolchain=toolchain)
    platform.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {{hps_spi_clk_IBUF}}]")

    add_designfiles(platform, coredir, mistex_yaml, 'vivado')

    defines = [
        ('XILINX', 1),
        ('LARGE_FPGA', 1),
        # ('MISTEX_HDMI', 1),

        # ('DEBUG_HPS_OP', 1),

        # On Xilinx we need this to get a proper clock tree
        ('CLK_100_EXT', 1),

        # disable bilinear filtering when downscaling
        # ('MISTER_DOWNSCALE_NN', 1),

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
    if toolchain == "vivado":
        platform.toolchain.pre_synthesis_commands += [
            f'set_property is_global_include true [get_files "../../../{build_id_path}"]',
            'set_property default_lib work [current_project]'
        ]

    add_mainfile(platform, coredir, mistex_yaml)

    platform.add_extension(extension)

    build_dir = get_build_dir(core)

    soc = BaseSoC(platform, core_name=core, toolchain=toolchain)
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
