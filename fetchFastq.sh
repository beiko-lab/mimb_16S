#!/bin/bash

#Set the project accession (example given here)
ACCESSION=PRJNA313530

#Put everything in a folder
mkdir -p sequence_data
cd sequence_data

#Fetch the project file manifest
curl -sLo MANIFEST.txt "http://www.ebi.ac.uk/ena/data/warehouse/search?query=%22study_accession%3D%22${ACCESSION}%22%22&result=read_run&fields=fastq_ftp,sample_alias,sample_accession&display=report"

#Fetch each of the noted FASTQ files
awk 'BEGIN{FS="\t";}{if (NR>1) {split($2, f, ";"); system("wget " f[1]); system("wget " f[2]);}}' MANIFEST.txt

#Fetch the metadata for each sample
for SAMPLE_ACCESSION in `tail -n +2 MANIFEST.txt | cut -f 4`
do
    #Get the XML report from EBI
    curl -sLo ${SAMPLE_ACCESSION}.txt "https://www.ebi.ac.uk/ena/data/view/${SAMPLE_ACCESSION}&display=xml"

    #If there is no metadata file, write the first line
    if [ ! -f "METADATA.txt" ]
    then
        #Scrape the metadata categories from the XML file, save them as the header
        awk 'BEGIN{ORS=""; OFS=""; i=1} {if ($0~/<SAMPLE_ATTRIBUTE>/) { getline; split($0,x,">"); split(x[2], y, "<"); tag[i]=y[1]; i+=1;}} END{print "#SampleID" "\t" "sample_name"; for (j=1; j<=i; j++){print "\t" tag[j];}}' ${SAMPLE_ACCESSION}.txt > METADATA.txt
    fi

    #Scrape the metadata values from the XML file, save them as a new row
    awk 'BEGIN{ORS=""; OFS=""; i=1} {if ($0~/ENA-RUN/) {getline; split($0, x, ">"); split(x[2], y, "<"); run=y[1];} if ($0~/SUBMITTER_ID/) { split($0, x, ">"); split(x[2], y, "<"); samplename=y[1];}; if ($0~/<SAMPLE_ATTRIBUTE>/) { getline; getline; split($0,x,">"); split(x[2], y, "<"); value[i]=y[1]; i+=1;}} END{print "\n"; print run "\t" samplename; for (j=1; j<=i; j++){print "\t" value[j];}}' ${SAMPLE_ACCESSION}.txt >> METADATA.txt
done
