#!/usr/bin/bash

# This script dispatches snpeff.

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/"
vcf_prefix="$prefix"/"combine_mutations/"
output_prefix="$prefix"/"snpeff_annotation/"

for dir in $vcf_prefix/*
do
    # sample name
    sample_name="${dir##*/}"
    echo "$sample_name"
    #vcf_sample_name="$(echo "$sample_name" | tr "_" "-")"
    vcf_sample_name="$sample_name"

    # vcf
    vcf="$dir"/"$vcf_sample_name"".vcf"

    # output path
    output_path="$output_prefix"/"$sample_name"/
    #mkdir $output_path

    # do if not done already
    if [ ! -d $output_path ]
    then

	    mkdir $output_path

	    qsub -V -cwd \
		    -e "./job_output_files/" \
		    -o "./job_output_files/" \
		    snpeff.sh \
			$vcf \
			$output_path
    fi
done
