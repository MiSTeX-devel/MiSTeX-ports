#!/bin/bash
CORE="$(basename $1)"
if [ -z "$CORE" ]; then
  echo "Usage: $0 <corename>"
  exit 1
fi
mkdir -p $CORE/generated
cd jtcores
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

sed 's/#.*$//g' jt${CORE}.qsf | grep VERILOG_MACRO | cut -d\" -f2 | sed -e 's/=/: /'  -e 's/^/  /g' >> $YAML