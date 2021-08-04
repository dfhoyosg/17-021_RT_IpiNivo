#!/usr/bin/bash

# This script dispatches recal.sh.

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/"
indel_realign_prefix="$prefix"/"results/preprocessing/indel_realign/"
all_sample_file_pairs="$prefix"/"scripts/matched_samples/matched_samples.txt"

IFS=$'\n'
for sme in $(cat $all_sample_file_pairs)
do
	general_name="$(echo "$sme" | cut -d $'\t' -f 1)"
	normal_name="$(echo "$sme" | cut -d $'\t' -f 2)"
	tumor_name="$(echo "$sme" | cut -d $'\t' -f 3)"

	# bams
	normal_bam="$indel_realign_prefix"/"$general_name"/"$normal_name""_merged_markdup_realigned.bam"
	tumor_bam="$indel_realign_prefix"/"$general_name"/"$tumor_name""_merged_markdup_realigned.bam"

	# check that not already done
	if [ ! -d "$prefix"/"results/preprocessing/recal/""$normal_name""-""$tumor_name"/ ]
	then

		qsub -V -cwd \
			-e "./job_output_files/" \
			-o "./job_output_files/" \
			recal.sh \
				$normal_bam \
				$general_name \
				$normal_name

		qsub -V -cwd \
			-e "./job_output_files/" \
			-o "./job_output_files/" \
			recal.sh \
				$tumor_bam \
				$general_name \
				$tumor_name
	fi
done
