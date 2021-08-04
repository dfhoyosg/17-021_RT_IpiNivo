#!/usr/bin/bash

# This script gets a TMB for each sample.

data_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/final_files/"

echo "Normal_Name"$'\t'"Tumor_Name"$'\t'"Number_Total_Mutations"$'\t'"Number_Nonsynonymous_Mutations"$'\t'"Number_Missense_Mutations"

IFS=$'\n'
for sme in $data_dir/*
do
	sample_name="${sme##*/}"
	normal_name="$(echo "$sample_name" | cut -d "-" -f 1)"
	tumor_name="$(echo "$sample_name" | cut -d "-" -f 2)"

	muts_file="$sme"/"$sample_name""_final_mutation_information.txt"

	num_all_muts=0
	num_nonsyn_muts=0
	num_missense_muts=0
	while read mut_type
	do

		# all mutations
		((num_all_muts++))

		# nonsynonymous
		if [[ "$mut_type" == *"missense_variant"* ]] || [[ "$mut_type" == *"stop_gained"* ]]
		then
			((num_nonsyn_muts++))

			# missense
			if [[ "$mut_type" == *"missense_variant"* ]]
			then
				((num_missense_muts++))
			fi
		fi
	done <<<$(tail -n+2 $muts_file | cut -d $'\t' -f 16)

	echo "$normal_name"$'\t'"$tumor_name"$'\t'"$num_all_muts"$'\t'"$num_nonsyn_muts"$'\t'"$num_missense_muts"
done
