#args=' -q rna -o {log}.out -e {log}.err -J {params.job_name} -R
#"{params.memory} span[hosts=1] " -n {threads} -m "compute10 compute11 compute12 compute13 compute14 compute15 compute16 compute09 compute08 compute06 compute05 compute07" '

#snakemake --drmaa "$args" \
#    --snakefile Snakefile \
#    --jobs 72 \
#    --resources all_threads=72 \
#    --latency-wait 50 \
#    --rerun-incomplete  \
#    --configfile config_rnaseq.yaml 


#!/bin/bash

## run this script on a qrsh session, not on the head node
## this will submit cluster qsub jobs and monitor them
## example command to submit:
## snakemake -j 9 --cluster-config cluster.json --cluster "sbatch -A {cluster.account} -p {cluster.partition} -n {cluster.n}  -t {cluster.time}"

##maybe also submit snake process to get logs

#$ -cwd
#$ -V
#$ -j yes
##$ -o snake.log ## because run two snake jobs at the same time
#$ -m beas
#$ -M svetlana.lebedeva@mdc-berlin.de
#$ -N "snake"

mkdir -p logs

echo "############################### START PIPELINE #############################"
echo $(date)

snakemake --unlock && ##necessary because a lot of killed snakes

snakemake --jobs 4 --cluster-config cluster_config.json --cluster "qsub -cwd -V -j yes -o {cluster.err} -m beas -M {cluster.account} -pe smp {cluster.n} -l mem_free={cluster.mem_free},h_vmem={cluster.mem_max} -l h_rt={cluster.time} -N {cluster.name}" --snakefile Snakefile --latency-wait 50 --rerun-incomplete --configfile config_rnaseq.yaml

