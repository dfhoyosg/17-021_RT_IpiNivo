#!/usr/bin/bash

# This script finds samples without KRAS mutations. Need to manually curate them.

IFS=$'\n'

outfile=$(pwd)/"tracking_files/formatted_kras_manual_curation_file.txt"
if [ -e $outfile ]; then rm $outfile; fi

kras_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/formatted_kras_bam_readcounts/"

all_sample_file_pairs="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/scripts/matched_samples/matched_samples.txt"

for sme in $(grep -f $(pwd)/"tracking_files/samples_to_manually_curate_KRAS.txt" $all_sample_file_pairs)
do
    # normal and tumor sample names
    patient="$(echo "$sme" | cut -d $'\t' -f 1)"
    pair_name="$patient"
    normal="$(echo "$sme" | cut -d $'\t' -f 2)"
    tumor="$(echo "$sme" | cut -d $'\t' -f 3)"

    ## KRAS readcount table
    file="$kras_prefix"/${patient}/${pair_name}_formatted_kras_manual_curation_file.txt

    cat $file >> $outfile
done 

cp $outfile ${outfile}.original
echo "ATTENTION!!"
echo "EDIT ${outfile} to determine final KRAS mutations"
echo "Select one most promising mutation per sample"
echo "Original file, ${outfile}.original, will be kept.."
