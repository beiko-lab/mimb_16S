#!/bin/bash

mkdir -p sequence_data/merged_reads
for fbase in `find ./sequence_data/ -name "*.fastq.gz" | cut -d "/" -f 3 | cut -d "_" -f 1 | sort | uniq`
do
    fbase=`basename ${fbase}`
    #Note the many variables that ought to be changed to suit each individual data set
    #fastq_maxns = 0 -> no sequences with N's
    #fastq_minlen = 50 -> sequence must have 50bp in length
    #fastq_minmergelen = 200 -> sequence must be 200bp in length after merging
    #fastq_minovlen = 15 -> sequence must have 15bp of overlap to be kept
    #fastq_truncqual = 10 -> truncate sequences after a Qscore of 10 is seen
    vsearch --fastq_mergepairs sequence_data/${fbase}_1.fastq.gz --reverse sequence_data/${fbase}_2.fastq.gz --fastq_maxns 0 --fastq_minlen 50 --fastq_minmergelen 200 --fastq_minovlen 15 --fastq_truncqual 10 --fastqout sequence_data/merged_reads/${fbase}_${fbase}_L001_R1_001.fastq
done
gzip sequence_data/merged_reads/*.fastq
