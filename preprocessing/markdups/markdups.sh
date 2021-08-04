#!/usr/bin/bash

# This script merges and marks duplicates.

# use with qsub

# inputs
base_name=$1
rg_bams_folder=$2

# software paths
java_path=/mnt/data/software/jdk1.8.0_171/bin/java
picard_path=/mnt/data/software/picard-2.11.0/picard.jar

tmp_path=$TMPDIR/tmp/
mkdir -p $tmp_path

output_path=$TMPDIR/output/
mkdir -p $output_path

input_path=$TMPDIR/input/
mkdir -p $input_path
cp $rg_bams_folder/* $input_path/
rg_bams_folder=$input_path

# create list of inputs to merge
markduped_files="$output_path"/"markduped_files.txt"
for i in $rg_bams_folder/*.bam
do
    echo $i
done >> $markduped_files

# input files to merge
inputs=$(cat $markduped_files | while read bam; do printf "I=$bam "; done)

# markdups and merge
output_file="$output_path/$base_name""_merged_markdup.bam"
metrics_file="$output_path/$base_name""_merged_markdup_metrics.txt"

$java_path -Xmx8g -jar $picard_path MarkDuplicates \
    $(echo "$inputs") \
    O=$output_file \
    METRICS_FILE=$metrics_file \
    TMP_DIR=$tmp_path \
    CREATE_INDEX=true \
    VALIDATION_STRINGENCY=SILENT

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/markdups/"
final_output_path=$final_output_prefix/$base_name/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
