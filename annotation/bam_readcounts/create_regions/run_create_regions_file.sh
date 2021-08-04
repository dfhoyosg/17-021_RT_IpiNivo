#!/usr/bin/bash

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/"
mutation_calling_prefix="$prefix"/"results/mutation_calling/"
output_prefix="$prefix"/"results/annotation/bam_readcounts/"
#job_output_files="./job_output_files/create_regions_file/"

for dir in $mutation_calling_prefix/*
do

    # patient name
    name="${dir##*/}"
    echo $name

    # mutation calling results
    mutect_results_folder="$dir"/"MuTect"/
    strelka_results_folder="$dir"/"Strelka/myAnalysis/results/"

    # output folder
    output_folder="$output_prefix"/"$name"/
    #mkdir $output_folder

    # only do if not already done
    if [ ! -d $output_folder ]
    then

	    mkdir $output_folder

	    #sbatch --time=10:00:00 \
	    #--output $job_output_files \
	    #--error $job_output_files \
	    bash create_regions_file.sh \
		$mutect_results_folder \
		$strelka_results_folder \
		$output_folder
    fi
done
