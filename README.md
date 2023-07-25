# MiSTeX



Usage example for Menu core:

```sh
echo export PATH="/opt/intelFPGA_lite/17.1/quartus/bin:$PATH"
# python3 [path_to_board_definition.py] [core_name]
python3 mistex_boards/terasic_deca_retro_cape.py Menu
```
Note: You can use an up to date quartus for Intel based development boards, unlike MiSTer.
For Xilinx based boards, you need a recent Vivado version installed.

You will need to have the LiteX python packages installed though `pip3 install litex`
and follow LiteX installation guide from https://github.com/enjoy-digital/litex/wiki/Installation
