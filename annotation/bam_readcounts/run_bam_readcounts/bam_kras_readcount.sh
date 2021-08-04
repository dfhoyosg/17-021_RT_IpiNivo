#!/usr/bin/bash

# This script runs bam readcount for KRAS regions
# This script is based on "bam_readcount.sh". The only change is "-b" option.

region_list=$1
bam=$2
output_file=$3

bam_readcount_path="/mnt/data/software/bam-readcount/bin/bam-readcount"
reference_genome="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/b37/human_g1k_v37_decoy.fasta"

## Write to TMPDIR then copy it to /mnt/data
file_name="${output_file##*/}"
temp_output=${TMPDIR}/$file_name

echo "Region:" $region_list
echo "Bam file:" $bam
echo "Output:" $output_file
echo "TMP:" $TMPDIR

$bam_readcount_path \
    -f $reference_genome \
    -l $region_list \
    -i \
    -w 1 \
    $bam \
    > $temp_output

cp $temp_output $output_file
