#!/usr/bin/bash

# This script merges the MuTect snv output. It also creates region files for snvs and indels for bam-readcount.

# input arguments
mutect_results_folder=$1
strelka_results_folder=$2
filtering_path=$3

# merge MuTect output (in this case did not call per chromosome)
# keeps the original output
cp $mutect_results_folder/mutect_stats.txt $mutect_results_folder/mutect_stats.txt.ori
cat $mutect_results_folder/mutect_stats.txt | grep -v -e "#" -e "judgement" -e "REJECT" > $mutect_results_folder/mutect_stats.tmp
mv $mutect_results_folder/mutect_stats.tmp $mutect_results_folder/mutect_stats.txt

# MuTect SNV results
mutect_snv_results=$mutect_results_folder/mutect_stats.txt
# Strelka SNV results
strelka_snv_results=$strelka_results_folder/passed.somatic.snvs.vcf
# Strelka Indel results
strelka_indel_results=$strelka_results_folder/passed.somatic.indels.vcf

# create region files for SNVs and Indels

# SNV region file (MuTect mutations already had "#" removed above)
cat $mutect_snv_results | grep -v -e "GL0" -e "NC_007605" -e "hs37d5" | \
    awk -v OFS='\t' '{ print $1, $2, $2 }' > $filtering_path/mutect_snv_regions.txt
cat $strelka_snv_results | grep -v -e "#" -e "GL0" -e "NC_007605" -e "hs37d5" | \
    awk -v OFS='\t' '{ print $1, $2, $2 }' > $filtering_path/strelka_snv_regions.txt
cat $filtering_path/mutect_snv_regions.txt $filtering_path/strelka_snv_regions.txt | \
    sort | uniq > $filtering_path/merged_snv_regions.txt

# Indel region file
IFS=$'\n'
cat $strelka_indel_results | grep -v -e "#" -e "GL0" -e "NC_007605" -e "hs37d5" | while read line
do

    chrom="$(echo $line | cut -d $'\t' -f 1)"
    pos="$(echo $line | cut -d $'\t' -f 2)"

    ref="$(echo $line | cut -d $'\t' -f 4)"
    alt="$(echo $line | cut -d $'\t' -f 5)"

    # insertions
    if (( ${#ref} < ${#alt} ))
    then
        final_pos=$pos
    # deletions
    else
        final_pos=$((pos + 1))
    fi

    echo "$chrom"$'\t'"$final_pos"$'\t'"$final_pos"

done | sort | uniq > $filtering_path/indel_regions.txt

# combine the SNV and Indel region files
cat $filtering_path/merged_snv_regions.txt $filtering_path/indel_regions.txt | sort | uniq > $filtering_path/all_snv_indel_regions.txt

# remove unnecessary files
rm $filtering_path/mutect_snv_regions.txt $filtering_path/strelka_snv_regions.txt $filtering_path/merged_snv_regions.txt $filtering_path/indel_regions.txt
