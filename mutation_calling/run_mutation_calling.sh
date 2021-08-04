#!/usr/bin/bash

# This script runs mutation calling.

job_files_prefix="./job_output_files/"
prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/"
recal_prefix="$prefix"/"results/preprocessing/recal/"

IFS=$'\n'

all_sample_file_pairs="$prefix"/"scripts/matched_samples/matched_samples.txt"

for sme in $(cat $all_sample_file_pairs)
do
    # normal and tumor sample names
    sample_name="$(echo "$sme" | cut -d $'\t' -f 1)"
    normal_name="$(echo "$sme" | cut -d $'\t' -f 2)"
    tumor_name="$(echo "$sme" | cut -d $'\t' -f 3)"

    # create job files output
    job_output_path="$job_files_prefix"/"$sample_name"/
    mutect_job_output_path="$job_output_path"/"MuTect/"
    strelka_job_output_path="$job_output_path"/"Strelka/"
    mkdir -p $mutect_job_output_path $strelka_job_output_path

    # preprocessed bams
    normal_bam="$recal_prefix"/"$sample_name"/"$normal_name"/"$normal_name""_merged_markdup_realigned_recal.bam"
    tumor_bam="$recal_prefix"/"$sample_name"/"$tumor_name"/"$tumor_name""_merged_markdup_realigned_recal.bam"

    # make sure not already done
    if [ ! -d "$prefix"/"results/mutation_calling/""$normal_name""-""$tumor_name"/ ]
    then

	    qsub -V -cwd \
		    -e $mutect_job_output_path/ \
		    -o $mutect_job_output_path/ \
		    run_mutect.sh \
			$sample_name \
			$normal_bam \
			$tumor_bam

	    qsub -V -cwd \
		    -e $strelka_job_output_path/ \
		    -o $strelka_job_output_path/ \
		    run_strelka.sh \
			$sample_name \
			$normal_bam \
			$tumor_bam
    fi
done
