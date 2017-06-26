#! /usr/bin/env bash
#BSUB -n 1 
#BSUB -J rRNA
#BSUB -q normal

# extract out rRNA sequences (defined by gene_biotype:rRNA)

gunzip -c Homo_sapiens.GRCh38.ncrna.fa.gz \
    | fasta_formatter -t \
    | awk '{FS = "\t"} $1 ~ /gene_biotype:rRNA/ {print ">"$1"\n"$2}' \
    | > Homo_sapiens.GRCh38.rRNA.fa
