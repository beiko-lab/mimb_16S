#!/bin/bash

#Set the project accession (example given here)
ACCESSION=PRJNA313530

#Put everything in a folder
mkdir -p sequence_data
cd sequence_data

#Fetch the project file manifest
curl -sLo MANIFEST.txt "http://www.ebi.ac.uk/ena/data/warehouse/search?query=%22study_accession%3D%22${ACCESSION}%22%22&result=read_run&fields=fastq_ftp,sample_alias,sample_accession&display=report"

#Make the directory that will contain all of the files to be imported to QIIME
mkdir -p import_to_qiime
cd import_to_qiime

#Make the required metadata.yml file for QIIME that lists the PHRED offset value
echo "{'phred-offset': 33}" > metadata.yml

#Fetch each of the noted FASTQ files
awk 'BEGIN{FS="\t";}{if (NR>1) {split($2, f, ";"); system("wget " f[1]); system("wget " f[2]);}}' ../MANIFEST.txt

#Print the header of the MANIFEST file that QIIME requires
echo "sample-id,filename,direction" > MANIFEST

for RUN_ACCESSION in `tail -n +2 ../MANIFEST.txt | cut -f 1`
do
    # Name the files according to QIIME/Illumina conventions and fill the MANIFEST file needed for `qiime tools import`
    mv ${RUN_ACCESSION}_1.fastq.gz ${RUN_ACCESSION}_S0_L001_R1_001.fastq.gz
    echo "${RUN_ACCESSION},${RUN_ACCESSION}_S0_L001_R1_001.fastq.gz,forward" >> MANIFEST
    mv ${RUN_ACCESSION}_2.fastq.gz ${RUN_ACCESSION}_S0_L001_R2_001.fastq.gz
    echo "${RUN_ACCESSION},${RUN_ACCESSION}_S0_L001_R2_001.fastq.gz,reverse" >> MANIFEST
done

cd ..

#Fetch the metadata for each sample
for SAMPLE_ACCESSION in `tail -n +2 MANIFEST.txt | cut -f 4`
do
    #Get the XML report from EBI
    curl -sLo ${SAMPLE_ACCESSION}.txt "https://www.ebi.ac.uk/ena/data/view/${SAMPLE_ACCESSION}&display=xml"

    #If there is no metadata file, write the first line
    if [ ! -f "METADATA.txt" ]
    then
        #Scrape the metadata categories from the XML file, save them as the header
        awk 'BEGIN{ORS=""; OFS=""; i=1} {if ($0~/<SAMPLE_ATTRIBUTE>/) { getline; split($0,x,">"); split(x[2], y, "<"); tag[i]=y[1]; i+=1;}} END{print "#SampleID\tsample_alias\tbee_type"; for (j=1; j<=i; j++){if (tag[j] != "") {print "\t" tag[j];}}}' ${SAMPLE_ACCESSION}.txt > METADATA.txt
        # There are two metadata columns with the same name, so QIIME requires us to rename the one to avoid errors
        sed -i 's/BioSampleModel/BioSampleModelA/' METADATA.txt
    fi

    #Scrape the metadata values from the XML file, save them as a new row
    awk 'BEGIN{ORS=""; OFS=""; i=1} {if ($0~/ENA-RUN/) {getline; split($0, x, ">"); split(x[2], y, "<"); run=y[1];} if ($0~/SUBMITTER_ID/) { split($0, x, ">"); split(x[2], y, "<"); samplename=y[1];}; if ($0~/<SAMPLE_ATTRIBUTE>/) { getline; getline; split($0,x,">"); split(x[2], y, "<"); value[i]=y[1]; i+=1;}} END{split(samplename, z, "_"); print "\n"; print run "\t" samplename "\t" z[2]; for (j=1; j<=i; j++){if (value[j] != "") {print "\t" value[j];}}}' ${SAMPLE_ACCESSION}.txt >> METADATA.txt

done
