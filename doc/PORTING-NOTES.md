# Project structure
- `setup_ubuntu.sh`: installs the software required to build cores.
    This does not include the FPGA vendor toolchain, which has to be installed separately.
- `requirements.txt`: contains the needed python packages for building cores
- `build-working-cores.sh`: Shell script to automate the build of  all cores, which have been marked as working in `cores/Readme.md`
- `rtl`: contains Verilog/VHDL cores for use in all ported cores
- `platforms`: This contains platform files, which can not, or have not be upstreamed to https://github.com/litex-hub/litex-boards
- `mistex_boards`: This contains the top level migen build files for the different FPGA boards.
- `cores`: contains ports of the different cores. The Template core is the most fundamental one, because it contains the port of
  the FPGA side of the MiSTer system (directory `sys` in the Tempalte core). This is included in all other ported cores,
  which have `use-template-sys: True`, which currently are all of the working cores. 

# Structure of a port
For example in `Arcade-DigDug` we have:

- `upstream/` directory: This contains the unmodified upstream MiSTer core as a git submodule. All needed modifications for porting
   are made outside this directory, so in that way it is immediately visible, which files were modified for the porting process.
- `Arcade-DigDug.sv`: This is the top level file of the game core itself. Frequently the only modification that is needed here, 
   is to include the file `build_id.vh` instead of `build_id.v`. The game core module provides the `emu` module, which
   is a submodule of `sys_top.v` in the `sys/` directory of the Template core.
- `rtl/` directory: This contains modified copies of all of the files in upstream, which had to be modified to port the core.
   The directory structure of this subdirectory should be identical to the directory structure of the `upstream/rtl/` directory.
   In that way it is directly obvious, which files have been modified for porting, and also it is easy to diff against upstream
   to find out what those modifications are.
   Ideally, ported files which contain non-portable code, like vendor specific primitives should be suffixed with
   the fpga-architecture name. For example in the DigDug core we have `rtl/pll_0002-xilinx7.v`, which contains 
   a Xilinx 7series specific PLL implementation.
- `MiSTeX.yaml`: This file is contains the information the build system needs to create the project for
   the respective vendor toolchain. 

# `MiSTeX.yaml`
This file contains the information necessary for the build system to automatically
generate and build the project file for the respective vendor toolchain.

```
mainfile: Arcade-DigDug.sv

use-template-sys: True

defines:
  MISTER_FB: 1

sourcedirs:
  - sys
  - upstream/rtl
  - upstream/rtl/cpu

quartus:
  sourcefiles:
    - sys/sys_top.sdc
    - sys/altera_pll_reconfig_top.v
    - sys/altera_pll_reconfig_core.v
    - sys/pll_audio_0002.v
    - sys/pll_hdmi_0002.v
    - sys/hdmi_config.sv
    - upstream/rtl/pll/pll_0002.v
    - upstream/rtl/dprams.v
    - upstream/rtl/pause.v

vivado:
  sourcefiles:
    - rtl/pll_0002-xilinx7.v
    - sys/xilinx7_mmcm_reconfig.v
    - sys/xilinx_pll_reconfig_top.v
    - sys/pll_hdmi_0002-xilinx7.v
    - sys/pll_audio_0002-xilinx7.v
    - rtl/dprams.v
    - rtl/pause.v
```

The different elements have the following function:
- `mainfile` contains the top level filename of the core
- `use-template-sys` This is usually set to `True`.
   That means the generated FPGA project will use the HDL from the `sys/` directory of the Template
   core (in `cores/Template`).
   In the MiSTer project each core port contains a `sys/` directory which is the FPGA
  part of the MiSTer system. The guideline in the MiSTer project, that this should be replaced with the
  files of the Template core, when there are updates in the MiSTer system. Unfortunately,
  some cores (like MemTest) have an old, incompatible `sys/`. Only in those cases we would use
  `use-template-sys: False`. In that case that would also mean that all the MiSTeX changes
  to the Template sys would have to be merged manually into the core 'sys/' by using a diff tool,
  for example.