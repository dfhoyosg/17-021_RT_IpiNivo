#!/usr/bin/bash

# This script runs snpeff.

input_vcf=$1
output_path=$2

# software paths
snpeff_path=/mnt/data/software/snpEff.v4.3t/snpEff.jar
java_path=/mnt/data/software/jdk1.8.0_171/bin/java

# vcf name
vcf_name="${input_vcf##*/}"
vcf_name="${vcf_name%.vcf}"

# annotate
$java_path -jar $snpeff_path ann \
    -noStats \
    -strict \
    -hgvs1LetterAa \
    -hgvs \
    -canon \
    -fastaProt $output_path/"$vcf_name"".fasta" \
    GRCh37.75 \
    $input_vcf \
    > $output_path/"$vcf_name""_ann.vcf"
