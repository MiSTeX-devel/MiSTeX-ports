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

from util import *
from mistex_boards.qmtech_mistex import *
from litex_boards.platforms import qmtech_xc7k325t

def main(coredir, core):
    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    toolchain = os.environ.get('MISTEX_TOOLCHAIN')
    if toolchain is None:
        toolchain = "vivado"
    platform = qmtech_xc7k325t.Platform(with_daughterboard=False, toolchain=toolchain)
    #platform.add_platform_command("set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {{hps_spi_clk_IBUF}}]")
    platform.add_platform_command("create_clock -name spi_clk -period 33.33 [get_ports {{hps_spi_clk}}]")

    build_dir = get_build_dir(core)
    add_designfiles(platform, coredir, mistex_yaml, 'vivado', build_dir=build_dir)

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

    soc = BaseSoC(platform, core_name=core, fpga_name="XC7K325T", toolchain=toolchain)
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
