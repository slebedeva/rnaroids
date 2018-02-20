# RNAroids

Pipeline to help investigate RNA dynamics and regulatory mechanisms during steroidogenesis.

Full credit goes to Neel Mukherjee and Kent Riemondy.

Goal of this pipeline is to process and quantify RNA-Seq data of paired-end type, coming from total RNA-Seq, 4sU metabolic labeling or subcellular fractionation.

This pipeline is being modified to run on SGE. **Work in progress!!!**

### General guidelines:

1. Put your fastq.gz files for run1 and run2 into the directory data/fastq/raw_data/ (or choose a different directory but keep the subdirectory structure like [yourdir]/fastq/raw_data/)

name your original paired end fastq files like:

SampleName_R1.fastq.gz
SampleName_R2.fastq.gz

(This may change in the future).

Note: If you have multiple samples, make sure that all the samples have the same number of replicates.

2. Modify the file pipeline/cluster_config.yaml to include paths to your data.

```
## directory for data
DATA: 
  #"../data"
  # or "yourdir" (don't forget to create subdirectories fastq/raw_data)

## directory for auxillary scripts
SRC: 
  "../src"  # don't need to change this

## directory for databases
DBASES: 
  "../dbases" # normally don't need to change this

GENOME:
  # put the path to your genome.fa, for example:
  # "/mygroup/me/genomes/hg19/hg19.fa"

GENOME_DIR:
  # this is the directory where the STAR index will be created, for example
  #"/mygroup/me/STAR_index_hg19_ERCC"

TRANSCRIPTS:
  # gtf file of your transcript annotation
  # "/path/to/gencodevN.gtf"

CHROM_SIZES:
  # create an index for your genome with `samtools faidx genome.fa`
  # "/path/to/genome.fai"

RRNA_FA:
  # put the rRNA sequence for your species here. for mouse and human, they are already provided in dbases/genome/rRNA/ , make sure to select the right species
  "../dbases/mm10/rRNA/Mus_musculus.GRCm38.ncrna.rRNA.fa" 
   
ERCC_FA:
  "../dbases/ercc/ERCC92.fa" # don't need to change this
  
## first 5p base to keep in fastqs # how many bases to trim from the 5' end? in case you have sequence quality issues
#5P: "3"
#5P: "10"

##threads

THR: "4"


## salmon and kallisto 

TRANSCRIPTS_FA:
#  "/path/to/transcripts/fasta/gencode.vM15.preMRNA.fa"


#SALMON_IDX: #currently not used in the pipeline
  #"../genomes/salmon_idx/gencode.v27.transcripts.idx"

KALLISTO_IDX: #you need to pre-generate kallisto index if you plan to use kallisto
  "/path/to/kallisto/idx/gencode.vM15.preMRNA.kall.idx"

```

3. Start the pipeline on the cluster (GridEngine scheduling system)

`qsub snakecharmer_mod.sh`


4. Explore the results under data directory! # To do: report
