#!/usr/bin/bash

# This script runs realign_target.sh.

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/"
markdups_prefix="$prefix"/"results/preprocessing/markdups/"
target_prefix="$prefix"/"results/preprocessing/realign_target/"
all_sample_file_pairs="$prefix"/"scripts/matched_samples/matched_samples.txt"

IFS=$'\n'
for sme in $(cat $all_sample_file_pairs)
do
        general_name="$(echo "$sme" | cut -d $'\t' -f 1)"
        normal_name="$(echo "$sme" | cut -d $'\t' -f 2)"
        tumor_name="$(echo "$sme" | cut -d $'\t' -f 3)"

        # markdup bams
        normal_bam="$markdups_prefix"/"$normal_name"/"$normal_name""_merged_markdup.bam"
        tumor_bam="$markdups_prefix"/"$tumor_name"/"$tumor_name""_merged_markdup.bam"

	realign_target=$target_prefix/$general_name/"$general_name"".intervals"

	# check that was not already done
	if [ ! -d "$prefix"/"results/preprocessing/indel_realign/""$normal_name""-""$tumor_name"/ ]
	then

		qsub -V -cwd \
			-e "./job_output_files/" \
			-o "./job_output_files/" \
			indel_realign.sh \
				$general_name \
				$normal_bam \
				$tumor_bam \
				$realign_target
	fi
done
