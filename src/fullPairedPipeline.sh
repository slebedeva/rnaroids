#!/bin/bash
#$ -m e
#$ -pe smp 4
#$ -l mem_free=32G,h_vmem=36G
#$ -cwd



### IMPORTANT ###
# reads should be gzipped fastq files and in a subdirectory named "fastq"
# name of the file should have the following format:
# samplename_readpair_replicate.fastq.gz 
# this could look like this total_R1_A.fastq.gz and total_R2_A.fastq.gz
# usage: fullPairedPipeline.sh  total_R1_A.fastq.gz total_R2_A.fastq.gz
# example usage on cluster: qsub -V -e total_A.e -o total_A.o fullPairedPipeline.sh  total_R1_A.fastq.gz total_R2_A.fastq.gz



# Number of processors THIS NEEDS TO MATCH -pe smp X at the this script
THREADS="4"

# Necessary files: Specific to your analysis
CHRSIZE="/data/ohler/Neel/Adrenal/H295R/data/accessory/chrSizes.txt" # tab delimited list of chrom names and sizes needed to convert bedgraph to bigwig
pri_rsemINDEX="/data/ohler/Neel/Adrenal/H295R/data/accessory/priRSEM/GC25_primary" # RSEM index to calculate primary and mature transcript expression
QChouse="/data/ohler/Neel/Adrenal/H295R/data/accessory/ERCC92.bed" # ERCC file to calculate strandedness using RSeqQC
rRNA_bwt="/data/ohler/Neel/Adrenal/H295R/data/accessory/ERCCrRNA/ERCCrRNA" # bowtie index with rRNA and ERCC 
GTF="/data/ohler/Neel/Adrenal/H295R/data/accessory/gencode.v25.annotation.gtf" # gencode 25 no scaffolds
INDEX="/data/ohler/Neel/Adrenal/H295R/data/accessory/STAR_noScaffold/" # STAR Index hg20, gencode 25 no scaffolds

# addJunc="/data/ohler/Neel/Adrenal/H295R/data/RNAseq/firstPass/addJuncNoscaffold.txt" # new junctions from first pass to be loaded on the fly during 2nd mapping


# Parameters for programs
dedup_params="--method adjacency --paired  --multimapping-detection-method NH " # parameters for deduplication by umi tools
starPARS_dedup="
--outFilterMultimapNmax 10 --outFilterMismatchNmax 10 --outFilterMismatchNoverReadLmax 0.04 \
--outSAMmultNmax 1 --outMultimapperOrder Random  --outSAMprimaryFlag AllBestScore \
--alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \
--alignSJoverhangMin 8  --alignSJDBoverhangMin 1 --sjdbScore 1 \
--outReadsUnmapped Fastx --outFilterType BySJout \
--outSAMtype BAM SortedByCoordinate --outSAMmode Full \
--outSAMattributes All  --outSAMattrIHstart 0  --outSAMstrandField intronMotif  \ 
" # mapping before deduplication
starPARS="
--outFilterMultimapNmax 10 --outFilterMismatchNmax 10 --outFilterMismatchNoverReadLmax 0.04 \
--outSAMmultNmax 1 --outMultimapperOrder Random  --outSAMprimaryFlag AllBestScore \
--alignIntronMin 20 --alignIntronMax 1000000 --alignMatesGapMax 1000000 \
--alignSJoverhangMin 8  --alignSJDBoverhangMin 1 --sjdbScore 1 \
--outFilterType BySJout \
--outSAMtype BAM SortedByCoordinate --outSAMmode Full \
--outSAMattributes All  --outSAMattrIHstart 0  --outSAMstrandField intronMotif  \ 
--outWigType bedGraph  --outWigNorm RPM \
--quantMode GeneCounts --readFilesCommand zcat 
" # final mapping parameters
rsemPARS="  --no-bam-output --estimate-rspd -q --paired-end " # RSEM parameters
strandSPthresh=".85" # strand specificity threshold

# executables/paths
SCRIPTS="/data/ohler/Neel/bioTools/" #Scripts
STAR="/data/ohler/Neel/bioTools/STAR-2.5.2b/bin/Linux_x86_64/STAR" # STAR Executable
GUIX="/gnu/var/guix/profiles/custom/ohlerlab/bin/" # ohler lab guix path
bowPATH="/data/ohler/Neel/bioTools/bowtie/" # bowtie path
STRINGTIE="/data/ohler/Neel/bioTools/stringtie-1.3.0.Linux_x86_64/stringtie" # stringtie-1.3.0
RSEM="/data/ohler/Lorenzo/bins/rsem_1_2_11/" # RSEM path




# 1. Generate the genome with annotations.
# 2. Map all the different samples, SE and PE separately, without using any 2-pass options.
# 3. Concatenate all SJ.out.tab files. Remove junctions on chrM (false positives, may slow down the 2nd pass).
# 4. For one of the samples, run the 2nd pass inserting the new junctions:
# STAR ... --genomeDir /path/to/pass1/genome/ --sjdbFileChrStartEnd /path/to/SJ.out.tab.combined.filtered --sjdbInsertSave All
# The last option will save the 2nd pass genome (with new junctions inserted) into _STARgenome directory in the run directory.
# 5. Re-map all sample  to this new genome.



### DO NOT MODIFY BELOW ####
[ $# -eq 0 ] && { echo "No fastq files provided"; exit 1; }

date1=$(date +"%s")

fullfile1=$1
fullfile2=$2
sample=${fullfile1%_*_*.fastq.gz}
fname=$(basename $fullfile1)
# lib=${fname%.fastq.gz}
lib=${fullfile1%.fastq.gz}
lib2=${fullfile2%.fastq.gz}
rep=${lib##*_R*_}



# extract UMIs and put them in readnames

if [ ! -d filtFastq/  ];
	then
		mkdir filtFastq
fi

if [ ! -s filtFastq/extract_${sample}_${rep}.log ] ;
echo "Stage: extract UMI and trim reads, START @ $(date)"

	then

		mkfifo filtFastq/${sample}_${rep}_1
		mkfifo filtFastq/${sample}_${rep}_2

		gunzip -c fastq/${fullfile1} > filtFastq/${sample}_${rep}_1 &
		gunzip -c fastq/${fullfile2} > filtFastq/${sample}_${rep}_2 &

		umi_tools extract -I filtFastq/${sample}_${rep}_1 \
		--read2-in=filtFastq/${sample}_${rep}_2 \
		--bc-pattern=NNNNNNNN  --bc-pattern2=NNNNNNNN \
		--stdout=filtFastq/tmp_${sample}_${rep}_1.fastq \
		--read2-out=filtFastq/tmp_${sample}_${rep}_2.fastq \
		-v 0 -L filtFastq/extract_${sample}_${rep}.log

		rm filtFastq/${sample}_${rep}_1
		rm filtFastq/${sample}_${rep}_2
		
	## remove positions 9,10 from the 5' end of both pairs from original reads -> lower quality and non-templated T/A enriched at position 9
		cat filtFastq/tmp_${sample}_${rep}_1.fastq | /data/ohler/Neel/bioTools/bin/fastx_trimmer -Q33 -f 3 -o filtFastq/trim_tmp_${sample}_${rep}_1.fastq
		cat filtFastq/tmp_${sample}_${rep}_2.fastq | /data/ohler/Neel/bioTools/bin/fastx_trimmer -Q33 -f 3 -o filtFastq/trim_tmp_${sample}_${rep}_2.fastq

		echo "Stage: extract UMI and trim reads, END @ $(date)"

	else

	wait

	echo "Stage: extract UMI and trim reads, Already Complete @ $(date)"

fi


# remove rRNA and ERCC reads with bowtie
if [ ! -s filtFastq/${sample}_${rep}_ERCCrRNA.bam ] ;
	then
	
		echo "Stage: Remove rRNA and ERCC reads with bowtie, START @ $(date)"

		${SCRIPTS}bowtie/bowtie -p ${THREADS} -q -X 1000 --fr --best --un filtFastq/filt_trim_tmp_${sample}_${rep}.fastq \
		/data/ohler/Neel/Adrenal/H295R/data/accessory/ERCCrRNA/ERCCrRNA \
		-1 filtFastq/trim_tmp_${sample}_${rep}_1.fastq \
		-2 filtFastq/tmp_${sample}_${rep}_2.fastq \
		--sam | samtools view -bhSF4 - | samtools sort - filtFastq/${sample}_${rep}_ERCCrRNA
		
		samtools index filtFastq/${sample}_${rep}_ERCCrRNA.bam
			
		echo "Stage: Remove rRNA and ERCC reads with bowtie, END @ $(date)"

	else
		wait
		echo "pipeStage: Remove rRNA and ERCC reads with bowtie, Already Complete @ $(date)"
fi


# align with star
if [ ! -s filtFastq/dup_${sample}_${rep}.bam ] ;
	then
	echo "Stage: First alignment with STAR and add XS tag, START @ $(date)"

	${STAR} --genomeDir ${INDEX} \
	--readFilesIn filtFastq/filt_trim_tmp_${sample}_${rep}_1.fastq  filtFastq/filt_trim_tmp_${sample}_${rep}_2.fastq \
	${starPARS_dedup} --runThreadN ${THREADS} --outBAMsortingThreadN ${THREADS} \
	--outFileNamePrefix filtFastq/${sample}_${rep}_

	

# add XS tag to unspliced reads for stringtie (otherwise intronless transcripts are not assigned a strand)
# used script from Dobin

	samtools view -h filtFastq/${sample}_${rep}_Aligned.sortedByCoord.out.bam | \
	awk -v strType=2 -f /data/ohler/Neel/bioTools/tagXSstrandedData.sh | \
	samtools view -bS - > filtFastq/dup_${sample}_${rep}.bam
	samtools index filtFastq/dup_${sample}_${rep}.bam

	rm filtFastq/tmp_${sample}_${rep}*.fastq
	rm filtFastq/trim_tmp_${sample}_${rep}*.fastq
	rm filtFastq/${sample}_${rep}_Aligned.sortedByCoord.out.bam
	rm filtFastq/filt_trim_tmp_${sample}_${rep}_1.fastq  filtFastq/filt_trim_tmp_${sample}_${rep}_2.fastq

echo "Stage: First alignment with STAR and add XS tag, END @ $(date)"

	else
		wait
		echo "Stage: First alignment with STAR and add XS tag, Already Complete @ $(date)"
fi


# deduplication
	
if [ ! -s filtFastq/${sample}_${rep}.bam ] ;
	then
	echo "Stage: deduplication, START @ $(date)"

	umi_tools dedup \
	--method="directional-adjacency" \
	--paired \
	-v 2 \
	-L filtFastq/dedup_${sample}_${rep}.log \
	-I filtFastq/dup_${sample}_${rep}.bam \
	-S filtFastq/dedup_${sample}_${rep}.bam
	
	#	--multimapping-detection-method=NH \

	# sort by read name so pairs are together for conversion back to fastq
	samtools sort -n filtFastq/dedup_${sample}_${rep}.bam filtFastq/${sample}_${rep}
	
	rm filtFastq/dedup_${sample}_${rep}.bam
	# rm filtFastq/dup_${sample}_${rep}.bam
	
	echo "Stage: deduplication, END @ $(date)"
	else
		wait
		echo "Stage: deduplication, Already Complete @ $(date)"
fi


# create fastq files from deduplicated bam
if [ ! -d dedup/  ];
	then
		mkdir dedup
fi
		

if [ ! -s dedup/${sample}_R2_${rep}.fastq.gz ] ;
	then


		echo "Stage: bam to fastq, START @ $(date)"
		
		
		${GUIX}bam2fastx -q -A -Q -P -N \
		-o dedup/${sample}_${rep}.fastq filtFastq/${sample}_${rep}.bam
		
		mv dedup/${sample}_${rep}.1.fastq  dedup/${sample}_R1_${rep}.fastq
		mv dedup/${sample}_${rep}.2.fastq  dedup/${sample}_R2_${rep}.fastq
		
		
		
		# Add unmapped back to fastq -> This is bad beacuse 1) unmapped read names don't have proper /1 /2 format, and 2) they have many N's
		# Therefore this step has been killed until more time is available to address properly. Below is a potential fix.
		# cat filtFastq/${sample}_${rep}_Unmapped.out.mate1 | sed 's/^\(@[^[:blank:]]*\)[[:blank:]]\+/\1_KILLTHIS/' | sed 's/_KILLTHIS00/\/1/g' >> dedup/${sample}_R1_${rep}.fastq
		# cat filtFastq/${sample}_${rep}_Unmapped.out.mate2 | sed 's/^\(@[^[:blank:]]*\)[[:blank:]]\+/\1_KILLTHIS/' | sed 's/_KILLTHIS00/\/2/g' >> dedup/${sample}_R2_${rep}.fastq
		
		cd dedup/
		gzip ${sample}_R1_${rep}.fastq
		gzip ${sample}_R2_${rep}.fastq
		
		cd ../ 
	echo "Stage: bam to fastq, END @ $(date)"
	
	else
		wait
		echo "Stage: bam to fastq, Already done @ $(date)"


fi




## align with star
if [ ! -d bam/  ];
	then
		mkdir bam
fi
		
if [ ! -s bam/${sample}_${rep}.bam ] ;
	then
	echo "Stage: Second alignment with STAR and add XS tag, START @ $(date)"

	${STAR} --genomeDir ${INDEX} ${starPARS} \
	--readFilesIn dedup/${fullfile1}  dedup/${fullfile2} \
	--runThreadN ${THREADS} --outBAMsortingThreadN ${THREADS} \
	--outFileNamePrefix bam/${sample}_${rep}_

	

	## add XS tag to unspliced reads for stringtie (otherwise intronless transcripts are not assigned a strand)
	## used script from Dobin

	samtools view -h bam/${sample}_${rep}_Aligned.sortedByCoord.out.bam | \
	awk -v strType=2 -f /data/ohler/Neel/bioTools/tagXSstrandedData.sh | \
	samtools view -bS - > bam/${sample}_${rep}.bam
	samtools index bam/${sample}_${rep}.bam

	
	rm bam/${sample}_${rep}_Aligned.sortedByCoord.out.bam
	

echo "Stage: Second alignment with STAR and add XS tag, END @ $(date)"

	else
		echo "Stage: Second alignment with STAR and add XS tag, Already Complete @ $(date)"
fi



# Determine the strandedness of the library: Important for numerous downstream analysis

if [ ! -s bam/${sample}_${rep}.strand ] ;
	then

	echo "Stage: Determine strandedness, START @ $(date)"
	${GUIX}infer_experiment.py -i filtFastq/${sample}_${rep}_ERCCrRNA.bam -r ${QChouse} -s 500000 > bam/${sample}_${rep}.strand

		if [ "$(grep 1++ bam/${sample}_${rep}.strand | cut -d " " -f 7)" \> "${strandSPthresh}" ];
				then
					ssjStrand=" -read1 0 -read2 1 "
					rsemStrand=" --forward-prob 1 "
					htseqStrand=" --stranded=yes "
					rseqStrand=$(grep 1++ bam/${sample}_${rep}.strand | cut -d " " -f 6 | sed 's/://g' | sed "s/\"//g")

			elif [ "$(grep 2++ bam/${sample}_${rep}.strand | cut -d " " -f 7)" \> "${strandSPthresh}" ];
				then
					ssjStrand=" -read1 1 -read2 0 "
					rsemStrand=" --forward-prob 0 "
					htseqStrand=" --stranded=reverse "
					rseqStrand=$(grep 2++ bam/${sample}_${rep}.strand | cut -d " " -f 6 | sed 's/://g' | sed "s/\"//g")
			wait
		fi

	echo "Stage: Determine strandedness, END @ $(date)"
	
	else
		
		echo "Stage: Determine strandedness, Already Complete @ $(date)"
	
fi


# Create bigwig from bedgraph
if [ ! -d bigwig/  ];
	then
		mkdir bigwig
fi

if [ ! -s bigwig/${sample}_${rep}_rev_neg.bw ] ;
	then
		echo "Stage: Create bigwig from bedgraph, START @ $(date)"
		 		${SCRIPTS}bedGraphToBigWig bam/${sample}_${rep}_Signal.Unique.str2.out.bg ${CHRSIZE} bigwig/${sample}_${rep}_fwd.bw
		 		${SCRIPTS}bedGraphToBigWig bam/${sample}_${rep}_Signal.Unique.str1.out.bg ${CHRSIZE} bigwig/${sample}_${rep}_rev.bw
		 		awk '{$4=$4*-1;print}' bam/${sample}_${rep}_Signal.Unique.str1.out.bg > bam/${sample}_${rep}_rev.bg      
				${SCRIPTS}bedGraphToBigWig bam/${sample}_${rep}_rev.bg ${CHRSIZE} bigwig/${sample}_${rep}_rev_neg.bw

				rm bam/${sample}_${rep}_Signal*.bg bam/${sample}_${rep}_rev.bg
				
				echo "Stage: Create bigwig from bedgraph, END @ $(date)"
		

	else
		
                echo "Stage: Create bigwig from bedgraph, Already Complete @ $(date)"
fi


# Calculate primary transcript expression levels with RSEM
if [ ! -d pri_rsem/ ];
    then
        mkdir pri_rsem
fi

if [ ! -d pri_rsem/pri_${sample}_${rep} ];
    then
        mkdir pri_rsem/pri_${sample}_${rep}
fi
	
if [ ! -s pri_rsem/pri_${sample}_${rep}/pri_${sample}_${rep}.genes.results ] ;
    then
	echo "Stage: Calculate expression levels with pri_RSEM, START @ $(date)"
		mkfifo dedup/${sample}_${rep}_1
		mkfifo dedup/${sample}_${rep}_2
		gunzip -c dedup/${fullfile1} > dedup/${sample}_${rep}_1 &
		gunzip -c dedup/${fullfile2} > dedup/${sample}_${rep}_2 &
		
		${RSEM}rsem-calculate-expression --bowtie-path ${bowPATH} --forward-prob 0 -p ${THREADS} ${rsemPARS}  \
		dedup/${sample}_${rep}_1 dedup/${sample}_${rep}_2 \
		${pri_rsemINDEX} pri_rsem/pri_${sample}_${rep}/pri_${sample}_${rep}
		
		rm dedup/${sample}_${rep}_1 
		rm dedup/${sample}_${rep}_2

	echo "Stage:Calculate expression levels with pri_RSEM, END @ $(date)"

	else
    
	wait ${pid2}    
	echo "Stage: Calculate expression levels with pri_RSEM, Already Complete @ $(date)"
fi

wait


date2=$(date +"%s")
diff=$(($date2-$date1))



echo "pairedEnd RNA-Seq pipeline for ${sample}_${rep} is finsihed"
echo "$(($diff / 3600)) hours and $((($diff % 3600)/60)) minutes elapsed."



# clean up more files
# rm -rf filtFastq/${sample}_${rep}__STAR*
# rm filtFastq/${sample}_${rep}_rRNA.sam
# rm filt_trim_tmp_${sample}_${rep}_*.fastq
# gzip ${sample}_${rep}_SJ.out.tab
# gzip extract_${sample}_${rep}.log
# rm filtFastq/dedup_${sample}_${rep}.bam

exit 0
