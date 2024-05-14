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
from mistex_boards.xilinx_mistex import *
from litex_boards.platforms import qmtech_artix7_fgg676

def main(coredir, core):
    mistex_yaml = yaml.load(open(join(coredir, "MiSTeX.yaml"), 'r'), Loader=yaml.FullLoader)

    toolchain = os.environ.get('MISTEX_TOOLCHAIN')
    gui = False
    if toolchain == 'vivado-gui':
        toolchain="vivado"
        gui = True
    if toolchain is None:
        toolchain = "vivado"

    platform = qmtech_artix7_fgg676.Platform(with_daughterboard=False, toolchain=toolchain)
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

    soc = BaseSoC(platform, core_name=core, fpga_name="XC7A100T", toolchain=toolchain)
    builder = Builder(soc,
        build_backend="litex",
        gateware_dir=build_dir,
        software_dir=os.path.join(build_dir, 'software'),
        compile_gateware=True,
        compile_software=True,
        csr_csv="csr.csv",
        #bios_console="lite"
    )

    build_name = get_build_name(core)
    builder.build(build_name = build_name, run=not gui)
    if gui:
        lines  = []
        result = []
        cwd = os.getcwd()
        tclpath = join(build_dir, build_name + ".tcl")
        shname = "build_" + build_name + ".sh"
        shpath = join(build_dir, shname)
        with open(tclpath, 'r+') as f:
            lines = f.readlines()
        result.append('proc init {} {')
        for line in lines:
            if line.startswith("# Add pre-optimize commands"):
                result.append('}\n\nproc post_ila {} {\n')
            # TMP TMP TMP correct speedgrade until litex PR is merged
            if line.startswith("create_project"):
                result.append(line.replace("676-1", "676-2"))
                continue

            result.append(line)

        result += [
            "\n}\n\n",
            "init\n",
            "start_gui\n",
            'puts "type \'post_ila\' at the TCL console after you insert the debug core"\n'
        ]

        with open(tclpath, 'w') as f:
            f.writelines(result)
        os.chmod(shpath, 0o755)
        os.chdir(build_dir)
        from subprocess import call
        call(join(cwd, shpath), shell=True)

if __name__ == "__main__":
    handle_main(main)
