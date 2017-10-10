#!/bin/bash


mkdir -p logs

#$-cwd #start from current directory
#$-l mem_free=1G,h_vmem=2G
#$-l h_rt=2:0:0 #runtime
#$-V #export all the environmental variables into the context of the job
#$-j yes #merge the stderr with the stdout
#$-o logs/ #stdout, job log
#$-m beas # send email beginning, end, and suspension
#$-M svetlana.lebedeva@mdc-berlin.de
#$-pe smp 1
#$-N 'getrRNA'


# extract out rRNA sequences (defined by gene_biotype:rRNA)
# add in 45srRNA repeat sequence also

#submit: qsub getrRNA.sh <ensembl.ncRNA.fastq.gz>

fa=$1
rna=$2

pre=${fa%.fa.gz}

gunzip -c $fa \
    | fasta_formatter -t \
    | awk '{FS = "\t"} $1 ~ /gene_biotype:rRNA/ {print ">"$1"\n"$2}' \
    | cat - $rna > $pre.rRNA.fa

exit 0
