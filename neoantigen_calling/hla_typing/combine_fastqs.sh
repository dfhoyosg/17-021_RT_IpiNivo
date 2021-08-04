#!/usr/bin/bash

data_dir=$1
output_dir=$2

zcat "$data_dir"/*_1.fq.gz > "$output_dir"/"fastq_1.fastq"
zcat "$data_dir"/*_2.fq.gz > "$output_dir"/"fastq_2.fastq"
