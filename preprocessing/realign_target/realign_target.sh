#!/usr/bin/bash

# This script runs realign target.

# use with qsub

# input arguments
name=$1
normal_bam=$2
tumor_bam=$3

# threads
threads=10

# software paths
java_path=/mnt/data/software/jdk1.8.0_171/bin/java
gatk_path=/mnt/data/software/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar

normal_path="${normal_bam%/*}"/
tumor_path="${tumor_bam%/*}"/
normal_name="${normal_bam##*/}"
tumor_name="${tumor_bam##*/}"

tmp_path=$TMPDIR/tmp/
mkdir -p $tmp_path

input_path=$TMPDIR/input/
mkdir -p $input_path
#cp $normal_bam $input_path/
#cp $tumor_bam $input_path/
cp $normal_path/* $input_path/
cp $tumor_path/* $input_path/
normal_bam=$input_path/$normal_name
tumor_bam=$input_path/$tumor_name

output_path=$TMPDIR/output/
mkdir -p $output_path

# reference genome
ref_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/"
reference_genome=$ref_prefix/b37/human_g1k_v37_decoy.fasta
k_indels=$ref_prefix/indel_ref/1000G_phase1.indels.b37.vcf
mills_indels=$ref_prefix/indel_ref/Mills_and_1000G_gold_standard.indels.b37.vcf

# run RealignerTargetCreator
$java_path -Xmx8g -Djava.io.tmpdir=$tmp_path -jar $gatk_path \
    -T RealignerTargetCreator \
    -R $reference_genome \
    --known $k_indels \
    --known $mills_indels \
    -I $normal_bam \
    -I $tumor_bam \
    -nt $threads \
    -o $output_path/"$name"".intervals"

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/realign_target/"
final_output_path=$final_output_prefix/$name/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
