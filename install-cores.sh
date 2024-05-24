#!/bin/bash

DIR="$1"
SUFFIX="$2"

[ -z "$DIR" ] && DIR=build/qmtech_xc7a100t_mistex
[ -z "$SUFFIX" ] && SUFFIX=_A100T
[ -z "$HOST" ] && HOST=orangepizero2w.local

for i in $(find $DIR -name \*.bit)
do
  BASE=$(basename $i)
  DEST=${BASE/_MiSTeX/${SUFFIX}}
  TCL=$(dirname $i)/$(basename $i .bit).tcl
  if grep -q jtcores $TCL; then
    DEST=${BASE/_MiSTeX/}
    scp $i root@${HOST}:/media/fat/_Arcade${SUFFIX}/cores/jt${DEST}
  elif [[ "$i" == *Arcade_* ]]; then
    DEST=${BASE/Arcade_/Arcade-}
    DEST=${DEST/_MiSTeX/}
    scp $i root@${HOST}:/media/fat/_Arcade${SUFFIX}/cores/$DEST
  elif  [[ "$i" == */Menu_MiSTeX.bit ]]; then
    scp $i root@${HOST}:/media/fat/menu${SUFFIX}.bit
  elif [[ "$i" == *SMS_MiST* ]] || [[ "$i" == *NES_MiST* ]] ||  [[ "$i" == *NeoGeo_MiST* ]]; then
    scp $i root@${HOST}:/media/fat/_Console/$DEST
  elif [[ "$i" == *Minimig-AGA_MiST* ]] || [[ "$i" == *C64_MiST* ]]; then
    scp $i root@${HOST}:/media/fat/_Computer/$DEST
  else
    scp $i root@${HOST}:/media/fat/_Utility/$DEST
  fi
done
