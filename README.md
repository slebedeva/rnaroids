# RNAroids

Pipeline to investigate RNA dynamics and regulatory mechanisms during steroidogenesis

Full credit goes to Neel Mukherjee and Kent Riemondy.

This pipeline is being modified to run on SGE. Work in progress!!!

General guidelines:


name your original paired end fastq files like:

SampleBla_R1_Rep1.fastq.gz
SampleBla_R2_Rep1.fastq.gz

(This may change in the future).

With multiple samples and replicates, make sure to set up different directory for samples that miss a replicate.


Take care about your own genome and rRNA sequence and annotation. ERCC are provided.
