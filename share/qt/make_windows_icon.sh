#!/bin/bash
# create multiresolution windows icon
ICON_SRC=../../src/qt/res/icons/beardcoin.png
ICON_DST=../../src/qt/res/icons/beardcoin.ico
convert ${ICON_SRC} -resize 16x16 beardcoin-16.png
convert ${ICON_SRC} -resize 32x32 beardcoin-32.png
convert ${ICON_SRC} -resize 48x48 beardcoin-48.png
convert beardcoin-16.png beardcoin-32.png beardcoin-48.png ${ICON_DST}

