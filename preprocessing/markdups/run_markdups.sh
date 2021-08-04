#!/usr/bin/bash

# This script dispatches markdups.sh.

bwa_prefix="../../../results/preprocessing/bwa_align/"

for bwa_folder in $bwa_prefix/*
do
	sample="${bwa_folder##*/}"

	qsub -V -cwd \
		-e "./job_output_files/" \
		-o "./job_output_files/" \
		markdups.sh \
			$sample \
			$bwa_folder
done
