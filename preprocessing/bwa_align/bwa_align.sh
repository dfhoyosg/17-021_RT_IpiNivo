#!/usr/bin/bash

# use in qsub job

# input arguments
sample=$1
fastq_1=$2
fastq_2=$3
output_bam=$4

# reference genome
reference_genome="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/reference_files/b37/human_g1k_v37_decoy.fasta"

cp $fastq_1 $TMPDIR/
cp $fastq_2 $TMPDIR/

name_1="${fastq_1##*/}"
name_2="${fastq_2##*/}"

fastq_1=$TMPDIR/$name_1
fastq_2=$TMPDIR/$name_2
output_bam=$TMPDIR/$output_bam

# get the fastq read group
header="$(zcat $fastq_1 | head -n 1)"
ID="$(echo "$header" | cut -d " " -f 1 | cut -d ":" -f 3,4)"
SM="$sample"
PL="ILLUMINA"
LB="LB"

readgroup='@RG\tID:'$ID'\tSM:'$SM'\tLB:'$LB'\tPL:'$PL

# software paths
# bwa path
bwa_path="/mnt/data/software/bwa-0.7.17/bwa"
# samtools path
samtools_path="/mnt/data/software/samtools-1.6/samtools"

$bwa_path mem \
    -t 8 \
    -M \
    -R $readgroup \
    $reference_genome \
    $fastq_1 \
    $fastq_2 | $samtools_path view -bh - | $samtools_path sort -o $output_bam -

output_prefix="/mnt/data/david/ting/17-021_RT_Ipi_Nivo/results/preprocessing/bwa_align/"
output_path=$output_prefix/$sample/
mkdir -p $output_path
mv $output_bam $output_path/
