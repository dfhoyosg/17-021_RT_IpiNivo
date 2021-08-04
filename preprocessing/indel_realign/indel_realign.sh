#!/usr/bin/bash

# This script does indel realignment.
# use with qsub

# input arguments
name=$1
normal_bam=$2
tumor_bam=$3
realign_target=$4

# software paths
java_path=/mnt/data/software/jdk1.8.0_171/bin/java
gatk_path=/mnt/data/software/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar

normal_path="${normal_bam%/*}"/
tumor_path="${tumor_bam%/*}"/
normal_name="${normal_bam##*/}"
tumor_name="${tumor_bam##*/}"
realign_target_name="${realign_target##*/}"

tmp_path=$TMPDIR/tmp/
mkdir -p $tmp_path

input_path=$TMPDIR/input/
mkdir -p $input_path
cp $realign_target $input_path/
cp $normal_path/* $input_path/
cp $tumor_path/* $input_path/
normal_bam=$input_path/$normal_name
tumor_bam=$input_path/$tumor_name
realign_target=$input_path/$realign_target_name

output_path=$TMPDIR/output/
mkdir -p $output_path

# reference genome
ref_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/"
reference_genome=$ref_prefix/b37/human_g1k_v37_decoy.fasta
k_indels=$ref_prefix/indel_ref/1000G_phase1.indels.b37.vcf
mills_indels=$ref_prefix/indel_ref/Mills_and_1000G_gold_standard.indels.b37.vcf

# make map output file
normal_name="${normal_bam%.bam}"
normal_name="${normal_name##*/}"
normal_output="$output_path"/"$normal_name""_realigned.bam"

tumor_name="${tumor_bam%.bam}"
tumor_name="${tumor_name##*/}"
tumor_output="$output_path"/"$tumor_name""_realigned.bam"

echo -e "$normal_name"".bam"$'\t'"$normal_output"$'\n'"$tumor_name"".bam"$'\t'"$tumor_output" > $output_path/map_file.map

# run IndelRealigner
$java_path -Xmx8g -Djava.io.tmpdir=$tmp_path -jar $gatk_path \
    -T IndelRealigner \
    -R $reference_genome \
    -known $k_indels \
    -known $mills_indels \
    --targetIntervals $realign_target \
    -I $normal_bam \
    -I $tumor_bam \
    -nWayOut $output_path/map_file.map

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/indel_realign/"
final_output_path=$final_output_prefix/$name/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
