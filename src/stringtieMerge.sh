#!/bin/bash
#$ -m e
#$ -pe smp 8
#$ -l mem_free=16G,h_vmem=18G
#$ -cwd



### IMPORTANT ###
# reads should be gzipped fastq files
# name of the file should have the following format:
# samplename_readpair_replicate this could look like this
# total_R1_A.fastq.gz and total_R2_A.fastq.gz
# usage: pairedRNAseqPipeline.sh  total_R1_A.fastq.gz total_R2_A.fastq.gz
# esample usage on cluster: qsub -V -e total_A.e -o total_A.o pairedRNAseqPipeline.sh  total_R1_A.fastq.gz total_R2_A.fastq.gz QRNA


STAR="/data/ohler/Neel/bioTools/STAR-2.5.2b/bin/Linux_x86_64/STAR" # STAR Executable
INDEX="/data/ohler/Neel/Adrenal/H295R/data/accessory/Star_index_99/" # STAR Index hg20, gencode 25
addJunc="/data/ohler/Neel/Adrenal/H295R/data/RNAseq/firstPass/addJunc.txt" # new junctions from first pass to be loaded on the fly during 2nd mapping
secondPassPARS="
--runThreadN 4 --clip5pNbases 9 \
--outFilterMultimapNmax 20 --outFilterMismatchNmax 999 --outFilterMismatchNoverReadLmax 0.04 \
--alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \
--alignSJoverhangMin 8  --alignSJDBoverhangMin 1 --sjdbScore 1 \
--outSAMunmapped Within --outFilterType BySJout \
--outSAMtype BAM SortedByCoordinate --outSAMmode Full \
--outSAMattributes All  --outSAMattrIHstart 0  --outSAMstrandField intronMotif  \ 
"
STRINGTIE="/data/ohler/Neel/bioTools/stringtie-1.3.0.Linux_x86_64/stringtie" # stringtie-1.3.0
GTF="/data/ohler/Neel/Adrenal/H295R/data/accessory/gencode.v25.annotation.gtf" # STAR-2.5.2b
GFFCOMPARE="/data/ohler/Neel/bioTools/gffcompare/gffcompare"

### DO NOT MODIFY BELOW ####

# merge stringtie gtfs

 ${STRINGTIE} --merge -p 8  -G ${GTF} -o stringtie/labH295Rmerged.gtf labGTFlist.txt
 ${STRINGTIE} --merge -p 8  -G ${GTF} -o stringtie/totH295Rmerged.gtf totGTFlist.txt
 ${STRINGTIE} --merge -p 8  -G ${GTF} -o stringtie/allH295Rmerged.gtf mergeGTFlist.txt

# need to run on workstation - library error on cluster
# /data/ohler/Neel/bioTools/gffcompare/gffcompare -r /data/ohler/Neel/Adrenal/H295R/data/accessory/gencode.v25.annotation.gtf -o stringtie/allH295R stringtie/allH295Rmerged.gtf
# /data/ohler/Neel/bioTools/gffcompare/gffcompare -r /data/ohler/Neel/Adrenal/H295R/data/accessory/gencode.v25.annotation.gtf -o stringtie/labH295R stringtie/labH295Rmerged.gtf
# /data/ohler/Neel/bioTools/gffcompare/gffcompare -r /data/ohler/Neel/Adrenal/H295R/data/accessory/gencode.v25.annotation.gtf -o stringtie/totH295R stringtie/totH295Rmerged.gtf

exit 0
