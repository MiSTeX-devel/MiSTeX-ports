#!/usr/bin/env python3
#
# This file is part of MiSTeX-Boards.
#
# Copyright (c) 2023 Hans Baier <hansfbaier@gmail.com>
# SPDX-License-Identifier: BSD-2-Clause
#

from mistex_boards.xilinx_mistex import *
from litex_boards.platforms import qmtech_xc7k325t

def main(coredir, core):
    def platform_factory(toolchain):
        return qmtech_xc7k325t.Platform(with_daughterboard=False, toolchain=toolchain)

    build_xilinx(platform_factory, coredir, core, "XC7K325T")


if __name__ == "__main__":
    handle_main(main)
