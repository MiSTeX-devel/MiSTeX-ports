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
from litex.gen.fhdl.module import LiteXModule
from litex.build.generic_platform import *
from litex.build.io import DDROutput
from platforms import qmtech_5cefa5

from litex.soc.integration.soc_core import SoCCore
from litex.soc.integration.builder import *
from litex.soc.interconnect.avalon import AvalonMMInterface
from litex.soc.cores.clock import CycloneVPLL

from litedram.modules import W9825G6KH6
from litedram.phy import GENSDRPHY
from litedram.frontend.avalon import LiteDRAMAvalonMM2Native

from util import *

import mistex_baseboard

# CRG ----------------------------------------------------------------------------------------------

# TODO: currently unused, replace top PLL
class _CRG(LiteXModule):
    def __init__(self, platform, sys_clk_freq):
        self.cd_sys     = ClockDomain()
        self.cd_sys_ps  = ClockDomain()
        self.cd_retro   = ClockDomain()
        self.cd_retro2x = ClockDomain()

        # Clk / Rst
        clk50 = platform.request("clk50")

        # PLL
        self.pll = pll = CycloneVPLL(speedgrade="-C8")
        pll.register_clkin(clk50, 50e6)
        pll.create_clkout(self.cd_sys, sys_clk_freq)
        pll.create_clkout(self.cd_sys_ps, sys_clk_freq, phase=45)
        pll.create_clkout(self.cd_retro,   50e6)
        pll.create_clkout(self.cd_retro2x, 100e6)
        sdram_clk = ClockSignal("sys_ps")
        self.specials += DDROutput(1, 0, platform.request("sdram_clock"), sdram_clk)


# Build --------------------------------------------------------------------------------------------

class BaseSoC(SoCCore):
    def __init__(self, platform, core_name, **kwargs):
        sys_clk_freq=80e6
        self.debug = False

        # CRG --------------------------------------------------------------------------------------
        self.crg = _CRG(platform, sys_clk_freq)
        self.platform = platform

        # SoCCore ----------------------------------------------------------------------------------
        kwargs["uart_name"]            = "serial"
        kwargs["uart_baudrate"]        = 115200
        kwargs["cpu_type"]             = "femtorv"
        kwargs["l2_size"]              = 0
        kwargs["bus_data_width"]       = 32
        kwargs["bus_address_width"]    = 32
        kwargs['integrated_rom_size']  = 0x8000
        kwargs['integrated_sram_size'] = 0x1000
        SoCCore.__init__(self, platform, sys_clk_freq, ident = f"{core_name} LiteX SoC on MiSTeX QMTech 5CEFA5", **kwargs)

        # SDRAM for scaler -------------------------------------------------------------------------
        sdrphy_cls = GENSDRPHY
        self.sdrphy = sdrphy_cls(platform.request("sdram", 0), sys_clk_freq)
        self.add_sdram("sdram",
            phy           = self.sdrphy,
            module        = W9825G6KH6(sys_clk_freq, "1:1"),
            l2_cache_size = 0
        )

        self.gamecore = Gamecore(platform, self, sys_clk_freq)

class Gamecore(Module):
    def __init__(self, platform, soc, sys_clk_freq) -> None:
        led         = platform.request("led")
        rgb         = platform.request("rgb")
        i2c         = platform.request("i2c")
        i2s         = platform.request("i2s")
        sdcard      = platform.request("sdcard")
        sdram       = platform.request("sdram", 1)
        audio       = platform.request("audio")
        spdif       = platform.request("spdif")
        hps_spi     = platform.request("hps_spi")
        hps_control = platform.request("hps_control")

        # ascal can't take more than 28 bits of address width
        avalon_data_width = 64
        avalon_address_width = 26

        scaler_ddram_port  = soc.sdram.crossbar.get_port(data_width=avalon_data_width)
        self.scaler_ddram = scaler_ddram   = AvalonMMInterface(data_width=avalon_data_width, adr_width=avalon_address_width)
        self.submodules.scaler_avalon_port = LiteDRAMAvalonMM2Native(scaler_ddram, scaler_ddram_port)

        emu_ddram_port = soc.sdram.crossbar.get_port(data_width=avalon_data_width, clock_domain="sys")
        self.emu_ddram = emu_ddram      = AvalonMMInterface(data_width=avalon_data_width, adr_width=avalon_address_width)
        self.submodules.emu_avalon_port = ClockDomainsRenamer("sys")(LiteDRAMAvalonMM2Native(emu_ddram, emu_ddram_port))

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
            p_ASCAL_RAMBASE = Constant(0x0, 32),

            i_CLK_50  = ClockSignal("retro"),
            i_CLK_100 = ClockSignal("retro2x"),

            # I2S
            o_HDMI_MCLK   = i2s.mclk,
            o_HDMI_SCLK   = i2s.sclk,
            o_HDMI_LRCLK  = i2s.lrclk,
            o_HDMI_I2S    = i2s.dat,
            #
            o_HDMI_TX_CLK = rgb.clk,
            o_HDMI_TX_DE  = rgb.de,
            o_HDMI_TX_D   = rgb.d,
            o_HDMI_TX_HS  = rgb.hsync,
            o_HDMI_TX_VS  = rgb.vsync,
            i_HDMI_TX_INT = rgb.int,

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
            o_AUDIO_SPDIF = spdif,

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

            i_HPS_SPI_MOSI = hps_spi.mosi,
            o_HPS_SPI_MISO = hps_spi.miso,
            i_HPS_SPI_CLK  = hps_spi.clk,
            i_HPS_SPI_CS   = hps_spi.cs_n,

            i_HPS_FPGA_ENABLE = hps_control.fpga_enable,
            i_HPS_OSD_ENABLE  = hps_control.osd_enable,
            i_HPS_IO_ENABLE   = hps_control.io_enable,
            o_HPS_IO_WIDE     = hps_control.io_wide,
            i_HPS_CORE_RESET  = hps_control.core_reset,

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

    platform = qmtech_5cefa5.Platform(with_daughterboard=False)
    build_dir = get_build_dir(core)

    add_designfiles(platform, coredir, mistex_yaml, 'quartus', build_dir)

    generate_build_id(platform, coredir)
    add_mainfile(platform, coredir, mistex_yaml)

    defines = mistex_yaml.get('defines', {})
    defines.update({
        "ALTERA": 1,
        "CYCLONEV": 1,
        "CLK_100_EXT": 1,
        "DISABLE_VGA": 1,
        "SKIP_ASCAL" : 1,
        # "SKIP_SHADOWMASK": 1,
        # "NO_SCANDOUBLER": 1,
        # "MISTER_DISABLE_ADAPTIVE": 1,
        # "MISTER_SMALL_VBUF": 1,
        "MISTER_DISABLE_YC": 1,
        "MISTER_DISABLE_ALSA": 1,
    })

    for key, value in defines.items():
        platform.add_platform_command(f'set_global_assignment -name VERILOG_MACRO "{key}={value}"')

    platform.add_platform_command("set_global_assignment -name TIMEQUEST_MULTICORNER_ANALYSIS OFF")
    platform.add_platform_command("set_global_assignment -name OPTIMIZE_POWER_DURING_FITTING OFF")
    platform.add_platform_command("set_global_assignment -name FINAL_PLACEMENT_OPTIMIZATION ALWAYS")
    platform.add_platform_command("set_global_assignment -name FITTER_EFFORT \"STANDARD FIT\"")
    platform.add_platform_command("set_global_assignment -name OPTIMIZATION_MODE \"HIGH PERFORMANCE EFFORT\"")
    platform.add_platform_command("set_global_assignment -name ALLOW_POWER_UP_DONT_CARE ON")
    platform.add_platform_command("set_global_assignment -name QII_AUTO_PACKED_REGISTERS \"SPARSE AUTO\"")
    platform.add_platform_command("set_global_assignment -name ROUTER_LCELL_INSERTION_AND_LOGIC_DUPLICATION ON")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC ON")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_EFFORT EXTRA")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_DUPLICATION ON")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_REGISTER_RETIMING ON")
    platform.add_platform_command("set_global_assignment -name OPTIMIZATION_TECHNIQUE SPEED")
    platform.add_platform_command("set_global_assignment -name MUX_RESTRUCTURE ON")
    platform.add_platform_command("set_global_assignment -name REMOVE_REDUNDANT_LOGIC_CELLS ON")
    platform.add_platform_command("set_global_assignment -name AUTO_DELAY_CHAINS_FOR_HIGH_FANOUT_INPUT_PINS ON")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_COMBO_LOGIC_FOR_AREA ON")
    platform.add_platform_command("set_global_assignment -name ADV_NETLIST_OPT_SYNTH_WYSIWYG_REMAP ON")
    platform.add_platform_command("set_global_assignment -name SYNTH_GATED_CLOCK_CONVERSION ON")
    platform.add_platform_command("set_global_assignment -name PRE_MAPPING_RESYNTHESIS ON")
    platform.add_platform_command("set_global_assignment -name ROUTER_CLOCKING_TOPOLOGY_ANALYSIS ON")
    platform.add_platform_command("set_global_assignment -name ECO_OPTIMIZE_TIMING ON")
    platform.add_platform_command("set_global_assignment -name PERIPHERY_TO_CORE_PLACEMENT_AND_ROUTING_OPTIMIZATION ON")
    platform.add_platform_command("set_global_assignment -name PHYSICAL_SYNTHESIS_ASYNCHRONOUS_SIGNAL_PIPELINING ON")
    platform.add_platform_command("set_global_assignment -name ALM_REGISTER_PACKING_EFFORT LOW")
    platform.add_platform_command("set_global_assignment -name OPTIMIZE_POWER_DURING_SYNTHESIS OFF")
    platform.add_platform_command("set_global_assignment -name ROUTER_REGISTER_DUPLICATION ON")
    platform.add_platform_command("set_global_assignment -name FITTER_AGGRESSIVE_ROUTABILITY_OPTIMIZATION ALWAYS")
    platform.add_platform_command("set_global_assignment -name SEED 1")

    platform.add_extension(mistex_baseboard.extension("altera", sdram_index=1))

    soc = BaseSoC(platform, core_name=core)
    builder = Builder(soc,
        build_backend="litex",
        gateware_dir=build_dir,
        software_dir=os.path.join(build_dir, 'software'),
        compile_gateware=True,
        compile_software=True,
        # csr_csv="csr.csv",
        bios_console="lite"
    )

    builder.build(build_name = get_build_name(core))

if __name__ == "__main__":
    handle_main(main)
