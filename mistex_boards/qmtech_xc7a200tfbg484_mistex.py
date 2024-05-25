#!/usr/bin/env python3
#
# This file is part of MiSTeX-Boards.
#
# Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause
#

from mistex_boards.xilinx_mistex import *
from litex_boards.platforms import qmtech_artix7_fbg484

def main(coredir, core):
    def platform_factory(toolchain):
        p = qmtech_artix7_fbg484.Platform(with_daughterboard=False, toolchain=toolchain)
        p.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {{hps_spi_clk_IBUF}}]")
        return p

    build_xilinx(platform_factory, coredir, core, "XC7A200T")

if __name__ == "__main__":
    handle_main(main)
