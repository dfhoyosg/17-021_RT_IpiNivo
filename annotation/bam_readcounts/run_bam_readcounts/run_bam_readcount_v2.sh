#!/usr/bin/bash

## v2:
## This script generates bam readcounts for a given snp/indel region list & KRAS top mutation sites (for KRAS manual curation)

IFS=$'\n'
output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/annotation/bam_readcounts/"
all_sample_file_pairs="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/scripts/matched_samples/matched_samples.txt"
job_output_files="./job_output_files/"
kras_region_list="./KRAS_mutation_regions.txt"
recal_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/recal/"

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

	# region list for snv/indel.
	region_list="$output_prefix"/$pair_name/all_snv_indel_regions.txt
	
	# preprocessed bams
	normal_bam=$recal_prefix/$pair_name/${normal}/${normal}_merged_markdup_realigned_recal.bam
	tumor_bam=$recal_prefix/$pair_name/${tumor}/${tumor}_merged_markdup_realigned_recal.bam

	# output files
	normal_output_file="$output_prefix"/$pair_name/"normal_bam_readcounts.txt"
	tumor_output_file="$output_prefix"/$pair_name/"tumor_bam_readcounts.txt"
	normal_kras_output_file="$output_prefix"/$pair_name/"normal_kras_bam_readcounts.txt"
	tumor_kras_output_file="$output_prefix"/$pair_name/"tumor_kras_bam_readcounts.txt"

	# do if not done yet
	if [ ! -f $normal_output_file ]
	then
    
		## normal bam read counts
		qsub -V -cwd \
			-o "$job_output_files" \
			-e "$job_output_files" \
			-N bam_readcount.sh.normal \
			bam_readcount.sh \
				$region_list \
				$normal_bam \
				$normal_output_file

		qsub -V -cwd \
			-o "$job_output_files" \
			-e "$job_output_files" \
			-N bam_kras_readcount.sh.normal \
			bam_kras_readcount.sh \
				$kras_region_list \
				$normal_bam \
				$normal_kras_output_file

		## tumor bam read counts
		qsub -V -cwd \
			-o "$job_output_files" \
			-e "$job_output_files" \
			-N bam_readcount.sh.tumor \
			bam_readcount.sh \
				$region_list \
				$tumor_bam \
				$tumor_output_file

		qsub -V -cwd \
			-o "$job_output_files" \
			-e "$job_output_files" \
			-N bam_kras_readcount.sh.tumor \
			bam_kras_readcount.sh \
				$kras_region_list \
				$tumor_bam \
				$tumor_kras_output_file
	fi
done
