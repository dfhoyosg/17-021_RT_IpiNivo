#!/usr/bin/bash

# This script runs Strelka.
# use with qsub

# input arguments
general_name=$1
normal_bam=$2
tumor_bam=$3

strelka_path=/mnt/data/software/strelka_workflow-1.0.15/

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

ref_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/"
reference_genome=$ref_prefix/b37/human_g1k_v37_decoy.fasta

# get a copy of the conig file
cp $strelka_path/etc/strelka_config_bwa_default.ini $output_path/config.ini

# change the config file for exome sequencing (skip depth filters)
sed -i '13s/.*/isSkipDepthFilters = 1/' $output_path/config.ini

# configure
$strelka_path/bin/configureStrelkaWorkflow.pl \
    --normal=$normal_bam \
    --tumor=$tumor_bam \
    --ref=$reference_genome \
    --config=$output_path/config.ini \
    --output-dir=$output_path/myAnalysis/

# run the analysis
cd $output_path/myAnalysis/
make -j 8

final_output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/mutation_calling/"
final_output_path=$final_output_prefix/$general_name/"Strelka"/
mkdir -p $final_output_path
mv $output_path/* $final_output_path/
