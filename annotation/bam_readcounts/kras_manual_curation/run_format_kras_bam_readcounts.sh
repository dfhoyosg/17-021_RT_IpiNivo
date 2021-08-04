#!/usr/bin/bash

## This script translates KRAS bam read count tables into "formatted_kras_manual_curation_file.txt"
## This script doesn't require "qsub"

## Output text file will contain
## [pairID], [mutation ID], [Normal depth: alt_count], [Tumor depth : alt_count]
## PAM51N.-1-PAM51PT12	12_25380275_T_G	20:20	89:85

IFS=$'\n'
output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/formatted_kras_bam_readcounts/"
all_sample_file_pairs="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/scripts/matched_samples/matched_samples.txt"
bam_readcounts_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/bam_readcounts/"
kras_vcf="$(pwd)"/"reference_data/kras_man_curation_snpeff_input_ann.vcf"

for sme in $(cat $all_sample_file_pairs)
do
    # normal and tumor sample names
    patient="$(echo "$sme" | cut -d $'\t' -f 1)"
    pair_name="$patient"
    normal="$(echo "$sme" | cut -d $'\t' -f 2)"
    tumor="$(echo "$sme" | cut -d $'\t' -f 3)"

    echo $pair_name
    echo $normal
    echo $tumor

    # KRAS bam readcount files
    normal_kras_bamreadcounts="$bam_readcounts_prefix"/${patient}/"normal_kras_bam_readcounts.txt"
    tumor_kras_bamreadcounts="$bam_readcounts_prefix"/${patient}/"tumor_kras_bam_readcounts.txt"

    # output path
    output_path=${output_prefix}/${patient}/
    #mkdir -p $output_path

    # do if not done already
    if [ ! -d $output_path ]
    then
	    mkdir -p $output_path
    
	    python3 ./format_kras_bam_readcounts.py \
		    ${pair_name} \
		    $kras_vcf \
		    ${normal_kras_bamreadcounts} \
		    ${tumor_kras_bamreadcounts} \
		    ${output_path}
    fi
done
