#!/bin/bash

DIR="$1"

[ -z "$DIR" ] && DIR=build/qmtech_xc7a100t_mistex

for i in $(find $DIR -name \*.bit)
do
  BASE=$(basename $i)
  DEST=${BASE/_MiSTeX/}
  if [[ "$i" == *Arcade_* ]] then
    DEST=${BASE/Arcade_/Arcade-}
    DEST=${DEST/_MiSTeX/}
    scp $i root@orangepizero2w.lan:/media/fat/_Arcade/cores/$DEST
  elif  [[ "$i" == */Menu_MiSTeX.bit ]] then
    scp $i root@orangepizero2w.lan:/media/fat/menu.bit
  elif [[ "$i" == *SMS_MiST* ]] || [[ "$i" == *NeoGeo_MiST* ]] then
    scp $i root@orangepizero2w.lan:/media/fat/_Console/$DEST
  else
    scp $i root@orangepizero2w.lan:/media/fat/_Utility/$DEST
  fi
done
