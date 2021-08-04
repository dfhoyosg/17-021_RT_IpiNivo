#!/usr/bin/bash

# This script gets the mean read lengths across fastqs.

data_dir_1="../../../data/WES_Data/novogene_pool1/raw_data/"
data_dir_2="../../../data/WES_Data/NS90_WES_Data/"

for data_dir in $data_dir_1 $data_dir_2
do
	for f in $data_dir/*/*.gz
	do
		qsub -V -cwd \
			-e "./job_output_files/" \
			-o "./job_output_files/" \
			get_mean_read_length.sh \
				$f
	done
done
