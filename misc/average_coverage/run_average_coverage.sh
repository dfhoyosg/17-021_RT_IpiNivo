#!/usr/bin/bash

# This script computes average coverages of the recal bams.

data_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/recal/"

for bam in $data_dir/*/*/*.bam
do
	name="${bam##*/}"
	qsub -V -cwd -N $name \
		-e "./job_output_files/" \
		-o "./job_output_files/" \
		average_coverage.sh \
			$name \
			$bam
done
