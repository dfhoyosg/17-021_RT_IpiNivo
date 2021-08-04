#!/usr/bin/bash

data_file="./17-021_WES_inventory_6-19-19.csv"

check_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/markdups/"

# remove header and last line
IFS=$'\n'
tail -n+2 $data_file | sed \$d | cut -d $'\t' -f 1,2 | while read line
do
	item1="$(echo "$line" | cut -d $'\t' -f 1)"
	item2="$(echo "$line" | cut -d $'\t' -f 2)"

	normal_sample="NS90_17_021_WBC_"$item1
	if [ -d "$check_dir"/"$normal_sample" ]
	then		
		if [ -d "$check_dir"/"NS90_"$item2 ]
		then
			tumor_sample="NS90_"$item2
		else
			tumor_sample=$item2
		fi

		if [ -d "$check_dir"/"$tumor_sample" ]
		then

			general_name="$normal_sample""-""$tumor_sample"

			echo "$general_name"$'\t'"$normal_sample"$'\t'"$tumor_sample"
		fi
	fi
done > "./matched_samples.txt"
