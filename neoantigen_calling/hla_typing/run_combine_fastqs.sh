#!/usr/bin/bash

# This script combines the raw fastqs into one pair.

# data directories
data_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/data/WES_Data/NS90_WES_Data/"

# output directory
output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/neoantigen_calling/hla_calling/combine_fastqs/"

# job output files
job_output_files="./job_output_files/"

# normal samples
IFS=$'\n'
normal_samples_file="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/scripts/matched_samples/matched_samples.txt"

# concatenate the files
cat $normal_samples_file | cut -d $'\t' -f 2 | sort | uniq | while read normal_sample
do
	echo "$normal_sample"

	# output dir
	output_dir="$output_prefix"/"$normal_sample"/
	mkdir $output_dir

	# concatenate the fastqs to have one pair
	qsub -V -cwd -e "$job_output_files" -o "$job_output_files" combine_fastqs.sh "$data_dir"/"$normal_sample"/ "$output_dir"
done
