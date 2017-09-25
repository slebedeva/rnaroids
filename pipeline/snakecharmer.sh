#!/usr/bin/env bash

#BSUB -J RNAroids 
#BSUB -o logs/snakemake_%J.out
#BSUB -e logs/snakemake_%J.err
#BSUB -R "select[mem>4] rusage[mem=4] " 
#BSUB -m "compute15 compute16 compute07 compute03"
#BSUB -q normal

set -o nounset -o pipefail -o errexit -x

args=' -q rna -o {log}.out -e {log}.err -J {params.job_name} -R
"{params.memory} span[hosts=1] " -n {threads} ' 
    

#### load necessary programs ####

# If programs are not all in the path then modify code to load 
# the necessary programs

# load modules
. /usr/share/Modules/init/bash
module load modules modules-init modules-python

module load ucsc/v308 
module load fastqc/0.10.1
module load bowtie/0.12.9
module load samtools/1.5
module load star/2.5.1b
module load subread/1.4.4

# other programs (not in modules)
# Salmon-0.8.2
# FASTX toolkit 0.0.13
# umi_tools v4.4
# umitools="/vol1/software/modules-python/python3/3.6.1/bin/umi_tools"

#snakemake_py3="/vol1/software/modules-python/python3/3.4.0/bin/snakemake"
#### execute snakemake ####

snakemake --drmaa "$args" \
    --snakefile Snakefile \
    --jobs 120 \
    --resources all_threads=120 \
    --latency-wait 50 \
    --rerun-incomplete  \
    --configfile config_rnaseq.yaml 
