from migen import *
from litex.soc.integration.builder import *
from litex.build.generic_platform import *

def extension(vendor, sdram_index=0):
    assert vendor == "altera" or vendor == "xilinx"

    iostandard   = ""
    rgb_attrs    = []
    snac_attrs   = []
    pullup_attr  = None
    sdcard_attrs = []
    sdram_attrs  = []
    dq_attrs     = []

    if vendor == "xilinx":
        iostandard   =   IOStandard("LVCMOS33")
        rgb_attrs    = [ Misc("IOB TRUE"), Misc("SLEW SLOW"), Misc("DRIVE 4") ]
        pullup_attr  =   Misc("PULLTYPE PULLUP")
        snac_attrs   = [ pullup_attr, Misc("DRIVE 16") ]
        sdcard_attrs = [ Misc("SLEW FAST") ]

    if vendor == "altera":
        iostandard   =   IOStandard("3.3-V LVTTL")
        rgb_attrs    = [ Misc("FAST_OUTPUT_REGISTER ON") ]
        pullup_attr  =   Misc("WEAK_PULL_UP_RESISTOR ON")
        snac_attrs   = [ pullup_attr, Misc('CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"') ]
        sdcard_attrs = [ Misc('CURRENT_STRENGTH_NEW "MAXIMUM CURRENT"') ]
        dq_attrs     = [ Misc("FAST_OUTPUT_ENABLE_REGISTER ON"),
                         Misc("FAST_INPUT_REGISTER ON")]
        sdram_attrs = [
            Misc("CURRENT_STRENGTH_NEW \"MAXIMUM CURRENT\""),
            Misc("FAST_OUTPUT_REGISTER ON"),
            Misc("ALLOW_SYNCH_CTRL_USAGE OFF"),
        ]

    result = [
        ("serial", 0,
            Subsignal("rx",   Pins("J3:14")),
            Subsignal("tx",   Pins("J3:12")),
            iostandard
        ),
        ("led", 0,
            Subsignal("hdd",   Pins("J2:51")),
            Subsignal("user",  Pins("J2:54")),
            Subsignal("power", Pins("J2:53")),
            iostandard
        ),
        ("hps_spi", 0,
            Subsignal("cs_n", Pins("J3:16")),
            Subsignal("mosi", Pins("J3:11")),
            Subsignal("miso", Pins("J3:13")),
            Subsignal("clk",  Pins("J3:17")), # This is a clock pin on the Artix 100T
            iostandard,
        ),
        ("hps_control", 0,
            Subsignal("core_reset",  Pins("J3:8")),
            Subsignal("fpga_enable", Pins("J3:7")),
            Subsignal("osd_enable",  Pins("J3:9")),
            Subsignal("io_enable",   Pins("J3:10")),
            iostandard,
        ),
        ("rgb", 0,
            Subsignal("d",      Pins(
                "J2:33 J2:34 J2:31 J2:32 J2:29 J2:30 J2:27 J2:28",
                "J2:25 J2:26 J2:23 J2:24 J2:17 J2:18 J2:15 J2:16",
                "J2:13 J2:14 J2:11 J2:12 J2:9  J2:10 J2:7  J2:8"), *rgb_attrs),
            Subsignal("de",     Pins("J2:21"), *rgb_attrs),
            Subsignal("clk",    Pins("J2:22"), *rgb_attrs),
            Subsignal("hsync",  Pins("J2:19"), *rgb_attrs),
            Subsignal("vsync",  Pins("J2:20"), *rgb_attrs),
            Subsignal("int",    Pins("J2:36")),
            iostandard
        ),
        ("spdif", 0, Pins("J2:35"), iostandard),
        # deprecated, use via pmod
        ("audio", 0,
            Subsignal("l", Pins("J2:42")),
            Subsignal("r", Pins("J2:41")),
            iostandard
        ),
        # deprecated, use via pmod
        ("i2s", 0,
            Subsignal("dat",    Pins("J2:37")),
            Subsignal("mclk",   Pins("J2:38")),
            Subsignal("lrclk",  Pins("J2:39")),
            Subsignal("sclk",   Pins("J2:40")),
            iostandard,
        ),
        ("pmod", 0,
            Subsignal("pin1",  Pins("J2:42")),
            Subsignal("pin2",  Pins("J2:41")),
            Subsignal("pin3",  Pins("J2:50")),
            Subsignal("pin4",  Pins("J2:52")),
            Subsignal("pin7",  Pins("J2:40")),
            Subsignal("pin8",  Pins("J2:38")),
            Subsignal("pin9",  Pins("J2:37")),
            Subsignal("pin10", Pins("J2:39")),
            iostandard
        ),
        ("pmod_mode", 0, Pins("J2:49"), iostandard),
        ("i2c", 0,
            Subsignal("sda",   Pins("J2:43")),
            Subsignal("scl",   Pins("J2:44")),
            iostandard,
        ),
        ("snac", 0,
            Subsignal("user",   Pins("J3:22 J3:20 J3:18 J3:19 J3:21 J3:23 J3:24")),
            *snac_attrs,
            iostandard,
        ),
        ("sdram", sdram_index,
            Subsignal("a",     Pins(
                "J3:57 J3:58 J3:59 J3:60 J3:50 J3:47 J3:48 J3:45",
                "J3:46 J3:43 J3:56 J3:44 J3:41")),
            Subsignal("ba",    Pins("J3:54 J3:55")),
            Subsignal("cs_n",  Pins("J3:53")),
            Subsignal("clk",   Pins("J3:42")),
            Subsignal("ras_n", Pins("J3:52")),
            Subsignal("cas_n", Pins("J3:51")),
            Subsignal("we_n",  Pins("J3:49")),
            Subsignal("dq", Pins(
                "J3:25 J3:26 J3:27 J3:28 J3:29 J3:30 J3:31 J3:32",
                "J3:40 J3:39 J3:38 J3:37 J3:36 J3:35 J3:33 J3:34"),
                *dq_attrs),
            *sdram_attrs,
            iostandard
        ),
        ("sdcard", 0,
            Subsignal("clk",  Pins("J2:58")),
            Subsignal("cmd",  Pins("J2:57"), pullup_attr),
            Subsignal("data", Pins("J2:60 J2:59 J2:55 J2:56"), pullup_attr),
            *sdcard_attrs,
            iostandard
        ),
    ]

    return result