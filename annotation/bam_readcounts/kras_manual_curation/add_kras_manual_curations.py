#!/usr/bin/python3

# This script adds KRAS manual curations to snpeff annotations.

# import packages
import argparse
import subprocess

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument("file_with_manual_curations", help="file with manual curations to add")
parser.add_argument("cohort_snpeff_dir", help="directory with cohort's snpeff annotations to alter")
parser.add_argument("vcf_with_kras_ann", help="pre-made snpeff vcf with KRAS annotation")
parser.add_argument("fasta_with_kras_ann", help="pre-made snpeff fasta with KRAS annotation")
args = parser.parse_args()
file_with_manual_curations = args.file_with_manual_curations
cohort_snpeff_dir = args.cohort_snpeff_dir
vcf_with_kras_ann = args.vcf_with_kras_ann
fasta_with_kras_ann = args.fasta_with_kras_ann

#file_with_manual_curations="out/formatted_kras_manual_curation_file.txt"
#cohort_snpeff_dir="/mnt/data/jlihm/pdac_prepost_chemo/results/annotation/snpeff_annotation_with_manual_curation"
#vcf_with_kras_ann="/mnt/data/pdac_practice/reference_files/KRAS_curation/kras_man_curation_snpeff_input_ann.vcf"
#fasta_with_kras_ann="/mnt/data/pdac_practice/reference_files/KRAS_curation/kras_man_curation_snpeff_input.fasta"


# read in pre-made annotations, turn into dictionaries

# vcf annotations
with open(vcf_with_kras_ann, "r") as f:
    lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]

premade_kras_vcf_ann_dict = {l[2] : l for l in lines}

# fasta annotations
with open(fasta_with_kras_ann, "r") as f:
    lines = [l.strip("\n") for l in f.readlines()]

ref_seq = (lines[0], lines[1])
premade_kras_fasta_ann_dict = {}

for i in range(len(lines)):
    sme = lines[i]
    if sme[0] == ">" and "Variant" in sme:
        chrom = sme.split()[2].split(":")[0]
        pos = sme.split()[2].split(":")[1].split("-")[0]
        ref = sme.split()[3].split(":")[1]
        alt = sme.split()[4].split(":")[1]
        mut = "{}_{}_{}_{}".format(chrom, pos, ref, alt)
        premade_kras_fasta_ann_dict[mut] = [ref_seq[0], ref_seq[1], lines[i], lines[i+1]]

# read in file with manual curations to add
with open(file_with_manual_curations, "r") as f:
    manual_curations_to_add = [l.strip("\n").split("\t") for l in f.readlines()]

for sme in manual_curations_to_add:
    print(sme)
    sample, mut, normal_reads, tumor_reads = sme
    
    # change the vcf file
    ori_vcf = "{}/{}/{}_ann.vcf".format(cohort_snpeff_dir, sample, sample)
    with open(ori_vcf, "r") as f:
        lines = [l.strip("\n") for l in f.readlines()]

    # add KRAS mutation
    premade_ann = premade_kras_vcf_ann_dict[mut]
    stuff = "\t".join(["chr{}".format(premade_ann[0]), premade_ann[1], 
                       "{}_{}".format(premade_ann[2], sample)] + \
                      premade_ann[3:-2] + [normal_reads, tumor_reads])
    lines += [stuff]
    
    new_vcf = "{}/{}/{}_ann_tmp.vcf".format(cohort_snpeff_dir, sample, sample)
    print(new_vcf)
    f=open(new_vcf, "w")
    for a_line in lines:
        f.write(a_line + "\n")
    f.close()


    # change the fasta file
    ori_fasta = "{}/{}/{}.fasta".format(cohort_snpeff_dir, sample, sample)
    with open(ori_fasta, "r") as f:
        lines = [l.strip("\n") for l in f.readlines()]
    premade_ann = premade_kras_fasta_ann_dict[mut]
    lines += premade_ann
    new_fasta = "{}/{}/{}_tmp.fasta".format(cohort_snpeff_dir, sample, sample)
    f=open(new_fasta, "w")
    for a_line in lines:
        f.write(a_line+"\n")
    f.close()

    command = ["mv", new_vcf, ori_vcf]
    subprocess.call(command)
    command = ["mv", new_fasta, ori_fasta]
    subprocess.call(command)
