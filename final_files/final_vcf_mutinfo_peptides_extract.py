#!/usr/bin/env python3

# This script does (with manual curation for KRAS):
# (1) Create a final vcf for phylogeny.
# (2) Creates a final mutation information file.
# (3) Extracts peptides for neoantigen calling.
#
# Procedure:
# (1) Run through annotated vcf. Pick one annotation per mutation.
# (2) Create a final vcf for phylogeny.
# (3) Create a final mutation information file.
# (4) Run through the fasta file. Extract the peptides corresponding 
#     to the matched mutation and write to file.

# import packages
import argparse
from Bio import SeqIO

# input arguments
desc = ("This script creates a final vcf for phylogeny, a final mutation "
        "information file, and mutant and wildtype peptide fasta files from "
        "a SnpEff-annotated vcf and a fasta file (version 4.3t).")
parser = argparse.ArgumentParser(description=desc)
parser.add_argument("patient_name", help="Patient Name (avoid underscores)")
parser.add_argument("normal_name", help="Normal Name (avoid underscores)")
parser.add_argument("tumor_name", help="Tumor Name (avoid underscores)")
parser.add_argument("ann_vcf_file", help="SnpEff-annotated vcf")
parser.add_argument("fasta_file", help="SnpEff-produced fasta file")
parser.add_argument("non_annotated_strelka_mutations", help="non-annotated Strelka mutations")
parser.add_argument("non_annotated_mutect_mutations", help="non-annotated MuTect mutations")
parser.add_argument("output_dir", help="output directory")
args = parser.parse_args()
patient_name = args.patient_name
normal_name = args.normal_name
tumor_name = args.tumor_name
ann_vcf_file = args.ann_vcf_file
fasta_file = args.fasta_file
non_annotated_strelka_mutations = args.non_annotated_strelka_mutations
non_annotated_mutect_mutations = args.non_annotated_mutect_mutations
output_dir = args.output_dir

# sample name (used in file names to be writen to)
#sample_name = "{}-{}-{}".format(patient_name, normal_name, tumor_name)
sample_name = "{}".format(patient_name)

#### CREATE FINAL VCF AND MUTATION FILE ####

# read in possible Strelka mutations
with open(non_annotated_strelka_mutations, "r") as f:
    lines = [l.strip("\n").split("\t") for l in f.readlines()]
strelka_muts = [x[2] for x in lines[1:]]
# read in possible MuTect mutations
with open(non_annotated_mutect_mutations, "r") as f:
    lines = [l.strip("\n").split("\t") for l in f.readlines()]
mutect_muts = [x[2] for x in lines[1:]]

# output final vcf
to_write_final_vcf = []
# output final mutation file
to_write_final_mutations_file = []

# read in annotated vcf
with open(ann_vcf_file, "r") as f:
    vcf_lines = [l.strip("\n").split("\t") for l in f.readlines() if l[0] != "#"]

# keep track of missense mutations for peptide extraction
missense_mutations = []
# go through the annotated lines
for line in vcf_lines:

    # mutation information
    chrom = line[0]
    pos = line[1]
    mut_id = line[2]
    # for the ID in the output peptide files (since SnpEff fasta files do not have the name)
    #name_in_mut_id = mut_id.split("_")[-1]
    name_in_mut_id = "_".join(mut_id.split("_")[4:])
    ref = line[3]
    alt = line[4]
    qual = line[5]
    filter_ = line[6]
    format_ = line[8]
    normal = line[9]
    tumor = line[10]

    # coverage information
    normal_tot, normal_ref = [int(x) for x in normal.split(":")]
    tumor_tot, tumor_ref = [int(x) for x in tumor.split(":")]

    normal_alt = normal_tot - normal_ref
    tumor_alt = tumor_tot - tumor_ref

    normal_vaf = 100 * normal_alt/normal_tot
    tumor_vaf = 100 * tumor_alt/tumor_tot

    # annotations always ocurr in the "INFO" column
    info = line[7]
    
    # Sometimes a mutation has multiple annotations. In order to keep things reasonably simple
    # we pick one annotation for each mutation. This means we report one gene per mutation. The 
    # order of the reported annotations is from "most deleterious" to "least deleterious". We 
    # want to prioritize missense mutations to discover potential neoantigens. Therefore we 
    # prefer to choose the annotation that contains a missense mutation in a transcript instead 
    # of perhaps a nonsense mutation in a different transcript that covers the same chromosome-
    # position location. We also remove annotations that are of low confidence.

    # all annotations are comma-separated
    all_annotations = info.split(";")[1].split(",")

    # keep subset of annotations without warnings and errors
    all_annotations = [ann for ann in all_annotations if "WARNING" not in ann.split("|")[-1] and 
                                                         "ERROR" not in ann.split("|")[-1]]

    # if there are still any annotations without warnings
    if all_annotations != []:
        # prioritize missense mutations
        missense_exists = False
        for ann in all_annotations:
            # search for missense in annotation slot
            if "missense_variant" in ann.split("|")[1].split("&"):
                # final annotation
                final_ann = ann

                # get the transcript
                transcript_id = final_ann.split("|")[6]

                # mutation -- matched mutation to transcript
                mut = (mut_id, transcript_id)
                #missense_mutations.append(mut)

                missense_exists = True
                break
        if not missense_exists:
            # final annotation
            final_ann = all_annotations[0]

        # gene
        gene = final_ann.split("|")[3]

        # manual curation and filter reads
        #if ((gene == "KRAS") or 
        #    (tumor_tot >= 10 and tumor_vaf >= 4 and normal_tot >= 7 and 
        #     normal_vaf <= 1 and tumor_alt >= 9)):
        if True:

            # if missense mutation, save the mutation that passed the filters
            if missense_exists == True:
                missense_mutations.append(mut)

            # caller(s) of mutation
            if mut_id in strelka_muts and mut_id in mutect_muts:
                callers = "MuTect,Strelka"
            elif mut_id in strelka_muts and mut_id not in mutect_muts:
                callers = "Strelka"
            elif mut_id in mutect_muts and mut_id not in strelka_muts:
                callers = "MuTect"
            else:
                #print("ISSUE! Can't identify mutation caller!")
                callers = "Manual_Curation"

            # annotation information
            mutation_type = final_ann.split("|")[1]
            putative_impact = final_ann.split("|")[2]
            gene_id = final_ann.split("|")[4]
            feature_type = final_ann.split("|")[5]
            feature_id = final_ann.split("|")[6]
            transcript_biotype = final_ann.split("|")[7]
            dna_mutation = final_ann.split("|")[9]
            aa_mutation = final_ann.split("|")[10]
            cds_position = final_ann.split("|")[12]
            aa_position = final_ann.split("|")[13]
            
            # for output vcf
            vcf_stuff = [chrom, pos, mut_id, ref, alt, qual, filter_, 
                         gene, format_, normal, tumor]
            to_write_final_vcf.append(vcf_stuff)

            # for mutation file
            mutation_file_stuff = [chrom, pos, mut_id, ref, alt, qual, filter_, 
                                   patient_name, normal_name, tumor_name, 
                                   gene, gene_id, feature_type, feature_id, 
                                   transcript_biotype, mutation_type, putative_impact, 
                                   dna_mutation, aa_mutation, cds_position, 
                                   aa_position, callers, 
                                   str(normal_tot), str(normal_ref), 
                                   str(normal_alt), str(normal_vaf), str(tumor_tot), 
                                   str(tumor_ref), str(tumor_alt), str(tumor_vaf)]
            mutation_file_stuff = ["Not_Applicable" if x == "" else x for x in mutation_file_stuff]
            to_write_final_mutations_file.append(mutation_file_stuff)

# order of chromosomes
chrom_order = ["chr{}".format(x) for x in list(range(1, 23)) + ["X", "Y", "MT"]]

# sort the outputs by chromosome and write to file
title = "\t".join(["#CHROM", "POS", "ID", "REF", "ALT", "QUAL",
                   "FILTER", "INFO", "FORMAT", "NORMAL", "TUMOR"])
to_write_final_vcf.sort(key=lambda x: (chrom_order.index(x[0]), int(x[1])))
to_write_final_vcf = [title] + ["\t".join(x) for x in to_write_final_vcf]
title = "\t".join(["#CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", 
                   "Patient_Name", "Normal_Name", "Tumor_Name", 
                   "Gene_Name", "Gene_ID", "Feature_Type", "Feature_ID",
                   "Transcript_BioType", "Mutation_Type", "Putative_Impact",
                   "DNA_Mutation", "Amino_Acid_Mutation",
                   "CDS_position/CDS_length", "Protein_position/Protein_length", "Callers", 
                   "NORMAL_Tot_Cov", "NORMAL_Ref_Cov", "NORMAL_Alt_Cov", "NORMAL_VAF (%)",
                   "TUMOR_Tot_Cov", "TUMOR_Ref_Cov", "TUMOR_Alt_Cov", "TUMOR_VAF (%)"])
to_write_final_mutations_file.sort(key=lambda x: (chrom_order.index(x[0]), int(x[1])))
to_write_final_mutations_file = [title] + ["\t".join(x) for x in to_write_final_mutations_file]

# write final vcf
with open("{}/{}_final.vcf".format(output_dir, sample_name), "w") as f:
    f.write("\n".join(to_write_final_vcf))
# write final mutation information
with open("{}/{}_final_mutation_information.txt".format(output_dir, sample_name), "w") as f:
    f.write("\n".join(to_write_final_mutations_file))

################ GATHER PEPTIDES FROM TRANSCRIPTS IN THE FASTA FILE ######################

# containers for the WT and MT 9-mers
wt_9mers, mt_9mers = [], []

# read in the protein sequences (reference and alterate)
prot_seqs = list(SeqIO.parse(fasta_file, "fasta"))
ref_seqs = prot_seqs[0::2]
alt_seqs = prot_seqs[1::2]

# go through the pairs of reference and alternate sequences
for r_seq, a_seq in zip(ref_seqs, alt_seqs):

    # amino acid sequences
    r_seq_aa = r_seq.seq
    a_seq_aa = a_seq.seq

    # mutation information from the fasta file
    desc = a_seq.description.split()
    chrom = desc[2].split(":")[0]
    pos_1 = desc[2].split(":")[1].split("-")[0]
    pos_2 = desc[2].split(":")[1].split("-")[1]
    ref_base = desc[3].split(":")[1]
    alt_base = desc[4].split(":")[1]
    aa_mut = desc[5].split(":")[1]
    transcript_id = desc[0]

    # ID
    ID = "_".join([chrom, pos_1, ref_base, alt_base, name_in_mut_id])

    # check if in considered annotations
    if (ID, transcript_id) in missense_mutations:

        # some basic checks
        if (pos_1 == pos_2 # check that DNA mutation in one position
            and ref_base != alt_base # check that ref and alt bases are different
            and aa_mut != "" # check that the amino acid change is nonsynonymous
            and "*" not in aa_mut # check that the mutation is not a nonsense mutation
            and "?" not in aa_mut): # check that all amino acids are known in the mutation

            # amino acid mutation information
            # position in python
            mut_pos = int(aa_mut[3:-1]) - 1
            ref_aa, alt_aa = aa_mut[2], aa_mut[-1]

            # check that it is a missense mutation
            if ref_aa != alt_aa:

                # find the 9-mers and do checking
                for i in range(9):

                    wt_pep = r_seq_aa[mut_pos - 8 + i : mut_pos + 1 + i]
                    mt_pep = a_seq_aa[mut_pos - 8 + i : mut_pos + 1 + i]

                    # do some checks
                    if (len(wt_pep) == len(mt_pep) == 9 and 
                        wt_pep != mt_pep and 
                        "*" not in wt_pep and "*" not in mt_pep and 
                        "?" not in wt_pep and "?" not in mt_pep and 
                        "U" not in wt_pep and "U" not in mt_pep):

                        wt_9mers.append(">" + ID + "_{}".format(i))
                        wt_9mers.append(str(wt_pep))
                        mt_9mers.append(">" + ID + "_{}".format(i))
                        mt_9mers.append(str(mt_pep))

# write the peptide files
with open("{}/{}_wt_peps.txt".format(output_dir, sample_name), "w") as wt_file:
    wt_file.write("\n".join(wt_9mers) + "\n")
with open("{}/{}_mt_peps.txt".format(output_dir, sample_name), "w") as mt_file:
    mt_file.write("\n".join(mt_9mers) + "\n")
