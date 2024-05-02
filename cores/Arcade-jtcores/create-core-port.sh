#!/bin/bash
# NOTE: for successfully running this script, you will need
# a working golang installation to run the jtcore binary

CORE="$(basename $1)"
if [ -z "$CORE" ]; then
  echo "Usage: $0 <corename>"
  exit 1
fi
mkdir -p $CORE/generated
cd jtcores
shift # get rid of $1, because setprj.sh tries to execute it
source setprj.sh
jtcore $CORE -mistex
cp -Pv cores/${CORE}/mistex/* ../${CORE}/generated
cd ../${CORE}/generated
for f in *; do
  if [ -L $f ]; then
    LINKSRC=$(readlink $f | cut -d/ -f2- | sed 's,/modules/,/jtcores/modules/,g')
    rm $f
    ln -sv $LINKSRC .
  fi
done
ls -l --color $PWD
YAML=../MiSTeX.yaml
MAINFILE=$(echo jt${CORE}_game*.v)
cat <<EOF >$YAML
mainfile: generated/$MAINFILE

use-template-sys: false

defines:
EOF

sed 's/#.*$//g' jt${CORE}.qsf | grep VERILOG_MACRO | grep -v 'MISTER.*None' | cut -d\" -f2 | sed -e 's/=/: /'  -e 's/^/  /g' | sed "s/ 'h/ 32'h/g" >> $YAML

cat <<EOF >>$YAML

sourcedirs:
  - ../jtcores/modules/jtframe/target/mistex/pll6144
  - ../jtcores/modules/jtframe/target/mistex/pll6293
  - ../jtcores/modules/jtframe/target/mistex/pll6671
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_cfg

sourcefiles:
  #### sys folder
  - ../jtcores/modules/jtframe/target/mistex/sys/sys_top.v
  - ../jtcores/modules/jtframe/target/mister/sys/ascal.vhd
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_hdmi_adj.vhd
  - ../jtcores/modules/jtframe/target/mistex/sys/hq2x.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/scandoubler.v
  - ../jtcores/modules/jtframe/target/mistex/sys/scanlines.v
  - ../jtcores/modules/jtframe/target/mister/sys/video_cleaner.sv
  - ../jtcores/modules/jtframe/target/mister/sys/shadowmask.sv
  - ../jtcores/modules/jtframe/target/mister/sys/gamma_corr.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/video_mixer.sv
  - ../jtcores/modules/jtframe/target/mister/sys/video_freezer.sv
  - ../jtcores/modules/jtframe/target/mister/sys/video_freak.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/arcade_video.v
  - ../jtcores/modules/jtframe/target/mister/sys/math.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/f2sdram_safe_terminator.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/osd.sv
  - ../jtcores/modules/jtframe/target/mister/sys/vga_out.sv
  - ../jtcores/modules/jtframe/target/mister/sys/yc_out.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/i2c.v
  - ../jtcores/modules/jtframe/target/mister/sys/alsa.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/i2s.v
  - ../jtcores/modules/jtframe/target/mistex/sys/spi_slave.vhd
  - ../jtcores/modules/jtframe/target/mister/sys/spdif.v
  - ../jtcores/modules/jtframe/target/mistex/sys/audio_out.v
  - ../jtcores/modules/jtframe/target/mistex/sys/iir_filter.v
  - ../jtcores/modules/jtframe/target/mister/sys/ltc2308.sv
  - ../jtcores/modules/jtframe/target/mister/sys/sigma_delta_dac.v
  - ../jtcores/modules/jtframe/target/mister/sys/mcp23009.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/ddr_svc.sv
  - ../jtcores/modules/jtframe/target/mister/sys/sysmem.sv
  - ../jtcores/modules/jtframe/target/mistex/sys/hps_io.v
  - ../jtcores/modules/jtframe/target/mister/sys/video_calc.v
  - ../jtcores/modules/jtframe/target/mistex/sys/hps_interface.v
  - ../jtcores/modules/jtframe/target/mistex/sys/top_crg.v
  - ../jtcores/modules/jtframe/target/mistex/sys/pll.v
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_audio.v
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_cfg.v
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_cfg_hdmi.v
  - ../jtcores/modules/jtframe/target/mistex/sys/pll_hdmi.v

  #### core files (game.qip)
EOF

grep _FILE game.qip | grep -v QIP_FILE | cut -d/ -f6- | sed 's,^,  - ../,g' | grep -v cores/${CORE}/mistex >> $YAML

cat <<EOF >>$YAML

quartus:
  platform-commands:
    - 'set_global_assignment -name SEARCH_PATH "\${CORE_DIR}/generated"'
    - 'set_global_assignment -name SEARCH_PATH "\${CORE_DIR}/../jtcores/cores/${CORE}/hdl"'
    - 'set_global_assignment -name SEARCH_PATH "\${CORE_DIR}/../jtcores/modules/jtframe/hdl/inc"'
    - 'set_global_assignment -name VERILOG_MACRO "MISTER=<None>"'

  sourcefiles:
    - mistex/sys_top.sdc
    - ../jtcores/modules/jtframe/target/mistex/pll6144/jtframe_pll6144/jtframe_pll6144_0002.v
    - ../jtcores/modules/jtframe/target/mistex/pll6293/jtframe_pll6293/jtframe_pll6293_0002.v
    - ../jtcores/modules/jtframe/target/mistex/pll6671/jtframe_pll6671/jtframe_pll6671_0002.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll/pll_0002.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll_audio/pll_audio_0002.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll_hdmi/pll_hdmi_0002.v

vivado:
  verilog-include-paths:
    - \${CORE_DIR}/generated
    - \${CORE_DIR}/../jtcores/cores/${CORE}/hdl
    - \${CORE_DIR}/../jtcores/modules/jtframe/hdl/inc

  sourcefiles:
    - ../jtcores/modules/jtframe/target/mistex/sys/sys_top.xdc
    - ../jtcores/modules/jtframe/target/mistex/pll6144/jtframe_pll6144/jtframe_pll6144_0002-xilinx7.v
    - ../jtcores/modules/jtframe/target/mistex/pll6293/jtframe_pll6293/jtframe_pll6293_0002-xilinx7.v
    - ../jtcores/modules/jtframe/target/mistex/pll6671/jtframe_pll6671/jtframe_pll6671_0002-xilinx7.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll/pll_0002-xilinx7.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll_audio/pll_audio_0002-xilinx7.v
    - ../jtcores/modules/jtframe/target/mistex/sys/pll_hdmi/pll_hdmi_0002-xilinx7.v
EOF
