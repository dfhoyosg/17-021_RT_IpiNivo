#!/usr/bin/bash

prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/"
annotation_prefix="$prefix"/"annotation/snpeff_annotation_with_manual_curation/"
caller_prefix="$prefix"/"annotation/combine_mutations/"
output_prefix="$prefix"/"final_files/"

pairs_file="$prefix"/"../scripts/matched_samples/matched_samples.txt"

for dir in $annotation_prefix/*
do
    # sample name
    sample_name="${dir##*/}"
    echo $sample_name

    # names
    vcf_name="$sample_name"
    normal_name="$(cat "$pairs_file" | grep "$sample_name" | cut -d $'\t' -f 2)"
    tumor_name="$(cat "$pairs_file" | grep "$sample_name" | cut -d $'\t' -f 3)"

    # annotated vcf
    ann_vcf="$annotation_prefix"/"$sample_name"/"$vcf_name""_ann.vcf"
    # fasta
    fasta="$annotation_prefix"/"$sample_name"/"$vcf_name"".fasta"

    # Strelka-called mutations
    strelka_vcf="$caller_prefix"/"$sample_name"/"$vcf_name""_Strelka_only.vcf"
    # MuTect-called mutations
    mutect_vcf="$caller_prefix"/"$sample_name"/"$vcf_name""_MuTect_only.vcf"

    # output directory
    output_path="$output_prefix"/"$sample_name"/

    # do if not already done
    if [ ! -d $output_path ]
    then
	    mkdir $output_path

	    python3 final_vcf_mutinfo_peptides_extract.py \
        	"$sample_name" \
	        "$normal_name" \
        	"$tumor_name" \
	        "$ann_vcf" \
        	"$fasta" \
	        "$strelka_vcf" \
        	"$mutect_vcf" \
	        "$output_path"
    fi
done
