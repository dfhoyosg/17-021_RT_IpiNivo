#!/usr/bin/bash

# This script runs MuTect.
# use with qsub

# input arguments
general_name=$1
normal_bam=$2
tumor_bam=$3

java_path=/mnt/data/software/jdk1.7.0_80/bin/java
mutect_path=/mnt/data/software/mutect-1.1.7/mutect-1.1.7.jar

normal_bam_path="${normal_bam%/*}"/
normal_bam_name="${normal_bam##*/}"
normal_bai_name="${normal_bam_name%.bam}"".bai"

tumor_bam_path="${tumor_bam%/*}"/
tumor_bam_name="${tumor_bam##*/}"
tumor_bai_name="${tumor_bam_name%.bam}"".bai"

tmp_path=$TMPDIR/tmp/
mkdir $tmp_path
input_path=$TMPDIR/input/
mkdir $input_path
cp $normal_bam_path/$normal_bam_name $input_path/
cp $normal_bam_path/$normal_bai_name $input_path/
cp $tumor_bam_path/$tumor_bam_name $input_path/
cp $tumor_bam_path/$tumor_bai_name $input_path/
normal_bam=$input_path/$normal_bam_name
tumor_bam=$input_path/$tumor_bam_name
output_path=$TMPDIR/output/
mkdir $output_path

# references
ref_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/"
reference_genome=$ref_prefix/b37/human_g1k_v37_decoy.fasta
cosmic=$ref_prefix/cosmic/CosmicCodingMuts_v86.vcf
dbsnp=$ref_prefix/dbsnp/dbsnp_138.b37.vcf

$java_path -Djava.io.tmpdir=$tmp_path -Xmx8g -jar $mutect_path \
    --analysis_type MuTect \
    --reference_sequence $reference_genome \
    --cosmic $cosmic \
    --dbsnp $dbsnp \
    --input_file:normal $normal_bam \
    --input_file:tumor $tumor_bam \
    --out $output_path/mutect_stats.txt

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/mutation_calling/"
final_output_path=$final_output_prefix/$general_name/"MuTect"/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
