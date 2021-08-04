#!/usr/bin/bash

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/"
mutation_calling_prefix="$prefix"/"results/mutation_calling/"
bam_readcounts_prefix="$prefix"/"results/annotation/bam_readcounts/"
output_prefix="$prefix"/"results/annotation/combine_mutations/"

for dir in $mutation_calling_prefix/*
do
    
    # sample
    sample_name="${dir##*/}"
    echo $sample_name

    # mutation calls
    mutect_snv_stats="$dir"/"MuTect/mutect_stats.txt"
    strelka_snv_vcf="$dir"/"Strelka/myAnalysis/results/passed.somatic.snvs.vcf"
    strelka_indel_vcf="$dir"/"Strelka/myAnalysis/results/passed.somatic.indels.vcf"

    # readcounts
    normal_readcounts="$bam_readcounts_prefix"/"$sample_name"/"normal_bam_readcounts.txt"
    tumor_readcounts="$bam_readcounts_prefix"/"$sample_name"/"tumor_bam_readcounts.txt"

    # output path
    output_path="$output_prefix"/"$sample_name"/
    #mkdir $output_path

    # run if not done
    if [ ! -d $output_path ]
    then

	    mkdir $output_path

	    # run script
	    python3 combine_mutations.py \
		$sample_name \
		$mutect_snv_stats \
		$strelka_snv_vcf \
		$strelka_indel_vcf \
		$normal_readcounts \
		$tumor_readcounts \
		$output_path
    fi
done
