#!/usr/bin/bash

# This script runs base recalibration.
# use with qsub

# input arguments
bam=$1
patient_name=$2
sample_name=$3

# software paths
java_path=/mnt/data/software/jdk1.8.0_171/bin/java
gatk_path=/mnt/data/software/GenomeAnalysisTK-3.8-1-0-gf15c1c3ef/GenomeAnalysisTK.jar

bam_path="${bam%/*}"/
bam_name="${bam##*/}"
bai_name="${bam_name%.bam}"".bai"

tmp_path=$TMPDIR/tmp/
mkdir -p $tmp_path
input_path=$TMPDIR/input/
mkdir -p $input_path
cp $bam_path/$bam_name $input_path/
cp $bam_path/$bai_name $input_path/
bam=$input_path/$bam_name
output_path=$TMPDIR/output/
mkdir -p $output_path

# reference genome
ref_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/"
reference_genome=$ref_prefix/b37/human_g1k_v37_decoy.fasta
k_indels=$ref_prefix/indel_ref/1000G_phase1.indels.b37.vcf
mills_indels=$ref_prefix/indel_ref/Mills_and_1000G_gold_standard.indels.b37.vcf
dbsnp=$ref_prefix/dbsnp/dbsnp_138.b37.vcf

# bam name
name="${bam%.bam}"
name="${name##*/}"

# run BaseRecalibrator
$java_path -Xmx8g -Djava.io.tmpdir=$tmp_path -jar $gatk_path \
    -T BaseRecalibrator \
    -R $reference_genome \
    -I $bam \
    -knownSites $dbsnp \
    -knownSites $k_indels \
    -knownSites $mills_indels \
    -o $output_path/"$name""_recal_data.table"

# recalibrate the data
$java_path -Xmx8g -Djava.io.tmpdir=$tmp_path -jar $gatk_path \
    -T PrintReads \
    -R $reference_genome \
    -I $bam \
    -BQSR $output_path/"$name""_recal_data.table" \
    -o $output_path/"$name""_recal.bam"

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/recal/"
final_output_path=$final_output_prefix/$patient_name/$sample_name/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
