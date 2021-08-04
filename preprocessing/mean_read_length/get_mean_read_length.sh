#!/usr/bin/bash

# run with qsub

fastq=$1

name="${fastq##*/}"

cp $fastq $TMPDIR/

zcat $TMPDIR/$name | awk '{if(NR%4==2) {count++; bases += length} } END{print bases/count}'
