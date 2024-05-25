#!/usr/bin/env python3
#
# This file is part of MiSTeX-Boards.
#
# Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause
#

from mistex_boards.xilinx_mistex import *
from litex_boards.platforms import qmtech_artix7_fgg676

def main(coredir, core):
    def platform_factory(toolchain):
        return qmtech_artix7_fgg676.Platform(with_daughterboard=False, toolchain=toolchain)

    build_xilinx(platform_factory, coredir, core, "XC7A100T")

if __name__ == "__main__":
    handle_main(main)
