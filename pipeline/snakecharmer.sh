#!/bin/bash

## run this script on a qrsh session, not on the head node
## this will submit cluster qsub jobs and monitor them
## example command to submit:
## snakemake -j 9 --cluster-config cluster.json --cluster "sbatch -A {cluster.account} -p {cluster.partition} -n {cluster.n}  -t {cluster.time}"
## You can also qsub snakecharmer.sh to get logs from this

#$ -cwd
#$ -V
#$ -j yes
#$ -o logs/
#$ -m beas
#$ -M svetlana.lebedeva@mdc-berlin.de
#$ -N "snake_cp"

mkdir -p logs

echo "############################### START PIPELINE #############################"
echo $(date)

snakemake --unlock && ##necessary because a lot of killed snakes

snakemake --jobs 4 --cluster-config cluster_config.json --cluster "qsub -cwd -V -j yes -o {cluster.err} -m {cluster.m} -M {cluster.account} -pe smp {cluster.n} -l h_vmem={cluster.h_vmem} -l h_rt={cluster.time} -N {cluster.name}" --snakefile Snakefile --latency-wait 50 --rerun-incomplete --configfile config_rnaseq.yaml

exit
