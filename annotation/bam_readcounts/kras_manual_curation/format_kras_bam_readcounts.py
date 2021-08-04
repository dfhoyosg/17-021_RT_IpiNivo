#!/usr/bin/env python3

# This script re-format KRAS bam readcounts into DP:AC
# Modified from David's "combine_mutations.py" script

# import packages
import argparse

# input arguments
parser = argparse.ArgumentParser()
parser.add_argument("patient", help="Patient name.")
parser.add_argument("kras_vcf", help="KRAS vcf.")
parser.add_argument("normal_readcounts_file", help="Normal KRAS base readcounts.")
parser.add_argument("tumor_readcounts_file", help="Tumor KRAS base readcounts.")
parser.add_argument("output_path", help="Output path for re-formatted KRAS bam readcounts")

args = parser.parse_args()
patient = args.patient
kras_vcf = args.kras_vcf
normal_readcounts_file = args.normal_readcounts_file
tumor_readcounts_file = args.tumor_readcounts_file
output_path = args.output_path

# important filtering data
bases = ["A", "C", "G", "T"]
chromosomes = [str(c) for c in list(range(1,23))] + ["X", "Y", "MT"]

##########################
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

def format_kras_mutations(patient_name, kras_vcf, normal_readcounts, tumor_readcounts):
    # read in KRAS_vcf
    with open(kras_vcf, "r") as f:
        kras_snv_lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]

    # all mutations to go through
    mutation_set = kras_snv_lines
    name = "manual_kras"
        
    # collect mutations
    mutations = []
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
        # Insertion
        elif (len(alt) > len(ref) and len(ref) == 1):
            bamreadcount_pos = pos
            bamreadcount_ref = ref
            bamreadcount_alt = "+" + alt[1:]
            mut_type = "Insertion"
        # Deletion
        elif (len(alt) < len(ref) and len(alt) == 1):
            bamreadcount_pos = str(int(pos) + 1)
            bamreadcount_ref = ref[1]
            bamreadcount_alt = "-" + ref[1:]
            mut_type = "Deletion"
        # reference and alternate not straight-forward SNV or Indel
        else:
            print("Issue with reference and alternate bases !!!")

        loc = "{}_{}".format(chrom, bamreadcount_pos)

        # Do some checks
        # 1,2) reference and alternative alleles are in A, C, G, T
        # 3) chromosome is in pre-defined list of chromosomes (chr1-22, X, Y, MT)
        # 4,5) translated location from VCF files match with location in bam readcounts
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
            print("bamreadcount_ref:{} ; bamreadcount_alt:{}".format(bamreadcount_ref, bamreadcount_alt))
            print()

        # Normal and tumor reference and alternate reads
        # Total depth defined as the sum of the reference and alternate reads
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

        if (n_tot != 0 and t_tot != 0 and t_alt > 0):
            #mut = "_".join([chrom, pos, ref, alt, patient])
            mut = "_".join([chrom, pos, ref, alt])
            stuff = [patient_name, mut, "{}:{}".format(n_tot, n_ref), "{}:{}".format(t_tot, t_ref)]
            stuff = "\t".join(stuff)
            mutations.append(stuff)

    # take the union of mutations
    mutations = set(mutations)
    return mutations


################################
# Analysis

# Readcounts
normal_readcounts = readcounts(normal_readcounts_file)
tumor_readcounts = readcounts(tumor_readcounts_file)

#kras_vcf="/mnt/data/pdac_practice/reference_files/KRAS_curation/kras_man_curation_snpeff_input_ann.vcf"
called_muts=format_kras_mutations(patient, kras_vcf, normal_readcounts, tumor_readcounts)

f=open("{}/{}_formatted_kras_manual_curation_file.txt".format(output_path, patient), "w")

for stuff in called_muts:
    f.write(stuff + "\n")

#with open("{}/{}_formatted_kras_manual_curation_file.txt".format(output_path, patient), "w") as f:
#    f.write("\n".join(to_write))

