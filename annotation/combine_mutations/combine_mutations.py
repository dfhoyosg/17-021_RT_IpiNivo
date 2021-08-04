#!/usr/bin/env python3

# This script combines MuTect and Strelka mutations (SNVs and Indels) without filtering on reads.

# import packages
import argparse

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument("patient", help="Patient name.")
parser.add_argument("mutect_snv_stats", help="Mutect SNV stats file.")
parser.add_argument("strelka_snv_vcf", help="Strelka SNV vcf.")
parser.add_argument("strelka_indel_vcf", help="Strelka Indel vcf.")
parser.add_argument("normal_readcounts_file", help="Normal base readcounts.")
parser.add_argument("tumor_readcounts_file", help="Tumor base readcounts.")
parser.add_argument("output_path", help="Output path for vcfs with union of called mutations and each caller's mutations.")
args = parser.parse_args()
patient = args.patient
mutect_snv_stats = args.mutect_snv_stats
strelka_snv_vcf = args.strelka_snv_vcf
strelka_indel_vcf = args.strelka_indel_vcf
normal_readcounts_file = args.normal_readcounts_file
tumor_readcounts_file = args.tumor_readcounts_file
output_path = args.output_path

# change format of patients for parsing
#patient = patient.replace("_", "-")

# important filtering data
bases = ["A", "C", "G", "T"]
chromosomes = [str(c) for c in list(range(1,23))] + ["X", "Y", "MT"]

# functions

# read in bam readcounts for the number of reads at a position
def readcounts(readcounts_file):
    with open(readcounts_file, "r") as f:
        lines = [l.strip("\n").split("\t") for l in f.readlines()]
    data_dict = {}
    for l in lines:
        chrom = l[0]
        pos = l[1]
        mini_dict = {}
        for sme in l[5:]:
            sme = sme.split(":")
            base = sme[0]
            count = int(sme[1])
            mini_dict[base] = count
        data_dict["{}_{}".format(chrom, pos)] = mini_dict
    return data_dict

# SNVs and Indels
def combine_mutations(mutect_snv_stats, 
                      strelka_snv_vcf, strelka_indel_vcf, 
                      normal_readcounts, tumor_readcounts):
    # read in MuTect results
    with open(mutect_snv_stats, "r") as f:
        mutect_snv_lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]
    # read in Strelka results
    with open(strelka_snv_vcf, "r") as f:
        strelka_snv_lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]
    with open(strelka_indel_vcf, "r") as f:
        strelka_indel_lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]

    # all mutations to go through
    all_mutation_sets = [mutect_snv_lines, strelka_snv_lines, strelka_indel_lines]
    all_names = ["MuTect", "Strelka", "Strelka"]

    # collect mutations
    mutect_mutations = []
    strelka_mutations = []
    mutations = []
    for mutation_set, name in zip(all_mutation_sets, all_names):
        for l in mutation_set:
            chrom = l[0]
            pos = l[1]
            ref = l[3]
            alt = l[4]

            # check if SNV or Indel (insertion or deletion)
            # apply bam-readcount conventions for positions and indels annotation

            # SNV
            if len(alt) == len(ref) == 1:
                bamreadcount_pos = pos
                bamreadcount_ref = ref
                bamreadcount_alt = alt
                mut_type = "SNV"
            # insertion
            elif (len(alt) > len(ref) and len(ref) == 1):
                bamreadcount_pos = pos
                bamreadcount_ref = ref
                bamreadcount_alt = "+" + alt[1:]
                mut_type = "Insertion"
            # deletion
            elif (len(alt) < len(ref) and len(alt) == 1):
                bamreadcount_pos = str(int(pos) + 1)
                bamreadcount_ref = ref[1]
                bamreadcount_alt = "-" + ref[1:]
                mut_type = "Deletion"
            # reference and alternate not straight-forward SNV or Indel
            else:
                print("Issue with reference and alternate bases !!!")

            loc = "{}_{}".format(chrom, bamreadcount_pos)

            # do some checks
            if ([b in bases for b in ref] == [True for b in ref] and 
                [b in bases for b in alt] == [True for b in alt] and 
                chrom in chromosomes and 
                loc in normal_readcounts.keys() and 
                loc in tumor_readcounts.keys()):

                print("bamreadcounts location:", loc)
                print("normal mini dict:", normal_readcounts[loc])
                print("tumor mini dict:", tumor_readcounts[loc])
                print(mut_type)
                print("ref:{} ; alt:{}".format(ref, alt))
                print("bamreadcount_ref:{} ; bamreadcount_alt:{}".format(bamreadcount_ref, 
                                                                         bamreadcount_alt))
                print()

                # normal and tumor reference and alternate reads
                # total depth defined as the sum of the reference and alternate reads
                # since we have quality filters we may not see all mutations 
                # in the MuTect and Strelka results within bamreadcounts

                # note: reference is always one letter of A,C,G,T

                # normal
                n_ref = normal_readcounts[loc][bamreadcount_ref]
                if bamreadcount_alt not in normal_readcounts[loc].keys():
                    n_alt = 0
                else:
                    n_alt = normal_readcounts[loc][bamreadcount_alt]
                n_tot = n_ref + n_alt

                # tumor
                t_ref = tumor_readcounts[loc][bamreadcount_ref]
                if bamreadcount_alt not in tumor_readcounts[loc].keys():
                    t_alt = 0
                else:
                    t_alt = tumor_readcounts[loc][bamreadcount_alt]
                t_tot = t_ref + t_alt
    
                if (n_tot != 0 and t_tot != 0):
                    mut = "_".join([chrom, pos, ref, alt, patient])

                    stuff = ["chr{}".format(chrom), pos, mut, ref, alt, 
                             ".", "PASS", "INFO", "DP:AP", 
                             "{}:{}".format(n_tot, n_ref), "{}:{}".format(t_tot, t_ref)]
                    stuff = "\t".join(stuff)

                    mutations.append(stuff)
                    if name == "MuTect":
                        mutect_mutations.append(stuff)
                    elif name == "Strelka":
                        strelka_mutations.append(stuff)

    # take the union of mutations
    mutations = set(mutations)
    mutect_mutations = set(mutect_mutations)
    strelka_mutations = set(strelka_mutations)
    return mutations, mutect_mutations, strelka_mutations

# analysis

# readcounts
normal_readcounts = readcounts(normal_readcounts_file)
tumor_readcounts = readcounts(tumor_readcounts_file)

# all mutations
all_muts = combine_mutations(mutect_snv_stats, strelka_snv_vcf, strelka_indel_vcf, 
                             normal_readcounts, tumor_readcounts)
called_muts, called_mutect_muts, called_strelka_muts = all_muts

# write mutation to VCF
title = ["#CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "NORMAL", "TUMOR"]
to_write = ["\t".join(title)]
to_write_mutect = ["\t".join(title)]
to_write_strelka = ["\t".join(title)]

for stuff in called_muts:
    to_write.append(stuff)
for stuff in called_mutect_muts:
    to_write_mutect.append(stuff)
for stuff in called_strelka_muts:
    to_write_strelka.append(stuff)

# write all mutations to file
with open("{}/{}.vcf".format(output_path, patient), "w") as f:
    f.write("\n".join(to_write))
# write vcfs for MuTect and Strelka only for tracking
with open("{}/{}_MuTect_only.vcf".format(output_path, patient), "w") as f:
    f.write("\n".join(to_write_mutect))
with open("{}/{}_Strelka_only.vcf".format(output_path, patient), "w") as f:
    f.write("\n".join(to_write_strelka))
