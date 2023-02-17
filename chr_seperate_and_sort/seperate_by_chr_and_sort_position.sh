#!/bin/bash
for CHR in {1..10} multiple unknown
do
awk -v CHR=${CHR} '$2==CHR {print $0}' $1 | sort -k3,3n > ../output/chr_${CHR}_$1
done
