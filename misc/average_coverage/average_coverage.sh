#!/usr/bin/bash

name=$1
bam=$2

# samtools version: 1.7 (using htslib 1.7-2)
depth="$(samtools depth -a $bam | awk '{c++;s+=$3}END{print s/c}')"

echo "$name"$'\t'"$depth"
