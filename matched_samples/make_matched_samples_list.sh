#!/usr/bin/bash

data_file="./17-021_WES_inventory_6-19-19.csv"

check_dir="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/data/WES_Data/combined_data/"

IFS=$'\n'

# remove the header and the last line
tail -n+2 $data_file | grep -v "incorrect" | cut -d $'\t' -f 1,2 | while read line
do
	item1="$(echo "$line" | cut -d $'\t' -f 1)"
        item2="$(echo "$line" | cut -d $'\t' -f 2)"

	normal_sample="NS90_17_021_WBC_""$item1"

	# check if the normal sample exists
	if [ -d "$check_dir"/"$normal_sample" ]
	then

		# check if the tumor sample exists
		if [ -d "$check_dir"/"NS90_""$item2" ]
		then
			tumor_sample="NS90_""$item2"
		elif [ -d "$check_dir"/"$item2" ]
		then
			tumor_sample="$item2"
		else
			tumor_sample="none"
		fi

		# if the tumor sample exists
		if [ $tumor_sample != "none" ]
		then

			general_name="$normal_sample""-""$tumor_sample"

			echo "$general_name"$'\t'"$normal_sample"$'\t'"$tumor_sample"
		fi

	fi

done > "./matched_samples.txt"
