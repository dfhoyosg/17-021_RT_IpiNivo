#!/usr/bin/bash

# This script finds samples without KRAS mutations. Need to manually curate them.

IFS=$'\n'
all_sample_file_pairs="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/scripts/matched_samples/matched_samples.txt"
snpeff_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/snpeff_annotation/"

outfile=$(pwd)/"tracking_files/samples_to_manually_curate_KRAS.txt"
if [ -e "${outfile}" ]; then rm ${outfile}; fi

for sme in $(cat $all_sample_file_pairs)
do
    # normal and tumor sample names
    patient="$(echo "$sme" | cut -d $'\t' -f 1)"
    pair_name="$patient"
    normal="$(echo "$sme" | cut -d $'\t' -f 2)"
    tumor="$(echo "$sme" | cut -d $'\t' -f 3)"

    ## output VCF
    vcf=$snpeff_prefix/$pair_name/${pair_name}_ann.vcf
    num_kras_muts="$(cat $vcf | grep "|KRAS|" | wc -l)"
    
    if (( $num_kras_muts == 0 ))
    then
        #echo "${vcf##*/}" >> ${outfile}
	echo "$patient" >> "$outfile"
    fi
done
