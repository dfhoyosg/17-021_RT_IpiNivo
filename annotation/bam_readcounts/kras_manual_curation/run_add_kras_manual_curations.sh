#!/usr/bin/bash

# Run from ~/pipeline/pdac_prepost_chemo/annotation/KRAS_curation.

kras_vcf="$(pwd)"/"reference_data/kras_man_curation_snpeff_input_ann.vcf"
kras_fasta="$(pwd)"/"reference_data/kras_man_curation_snpeff_input.fasta"

# copy snpeff directory to keep track of manual curation
ori_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/snpeff_annotation/"
new_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/snpeff_annotation_with_manual_curation/"
cp -r "$ori_dir" "$new_dir"

python3 add_kras_manual_curations.py \
    ./formatted_kras_manual_curation_file.txt \
    $new_dir/ \
    ${kras_vcf} \
    ${kras_fasta}
