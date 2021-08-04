#!/usr/bin/bash

# This script dispatches bwa_align.sh.

# data directories
data_dir_1="../../../data/WES_Data/novogene_pool1/raw_data/"
data_dir_2="../../../data/WES_Data/NS90_WES_Data/"

for data_dir in $data_dir_1 $data_dir_2
do
	for dir in $data_dir/*/
	do
		sample="${dir%/}"
		sample="${sample##*/}"
		fastq_names="$(ls $dir | grep 'gz$' | sed 's/_[12].fq.gz$//g' | sort | uniq)"
		for f_name in $fastq_names
		do
			f="$dir"/"$f_name"
			qsub -V -cwd \
				-e "./job_output_files/" \
				-o "./job_output_files/" \
				-pe smp 8 \
				bwa_align.sh \
					$sample \
					$f"_1.fq.gz" \
					$f"_2.fq.gz" \
					"$f_name"".bam"
		done
	done
done
