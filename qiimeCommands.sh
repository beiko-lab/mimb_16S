#!/bin/bash

# fetchFastq.sh must be run first!

#This command imports the FASTQ files into a QIIME artifact
qiime tools import --type 'SampleData[PairedEndSequencesWithQuality]' --input-path sequence_data/import_to_qiime --output-path reads

#Using DADA2 to analyze quality scores of 10 random samples
qiime demux summarize --p-n 10000 --i-data reads.qza --o-visualization qual_viz

#Denoising with DADA2. Using quality score visualizations, you can choose trunc-len-f and trunc-len-r (note: sequences < trunc-len in length are discarded!)
# The drop-off for the forward reads was not so bad, but there is a significant drop-off in quality for the reverse reads, so let's trim 10bp
qiime dada2 denoise-paired --i-demultiplexed-seqs reads.qza --o-table table --o-representative-sequences representative_sequences --p-trunc-len-f 150 --p-trunc-len-r 140 --p-trim-left-f 19 --p-trim-left-r 20 --p-n-threads 3

#This visualization shows us the sequences/sample spread
qiime feature-table summarize --i-table table.qza --o-visualization table_summary

#Filter out sequences with few samples
qiime feature-table filter-samples --i-table table.qza --p-min-frequency 5000 --o-filtered-table filtered_table

qiime feature-table summarize --i-table filtered_table.qza --o-visualization filtered_table_summary

#QIIME group has a 515f 806r 99% pre-clustered GreenGenes database
wget https://data.qiime2.org/2018.4/common/gg-13-8-99-515-806-nb-classifier.qza
#If you have a large amount of RAM (32GB or greater), try the larger SILVA database:
#wget https://data.qiime2.org/2018.4/common/silva-119-99-515-806-nb-classifier.qza

#Classify against it with Naive Bayes
qiime feature-classifier classify-sklearn --i-classifier gg-13-8-99-515-806-nb-classifier.qza --i-reads representative_sequences.qza --o-classification taxonomy

#Taxa bar plots
qiime taxa barplot --i-table filtered_table.qza --i-taxonomy taxonomy.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization taxa-bar-plots

#Steps for generating a phylogenetic tree
qiime alignment mafft --i-sequences representative_sequences.qza --o-alignment aligned_representative_sequences

qiime alignment mask --i-alignment aligned_representative_sequences.qza --o-masked-alignment masked_aligned_representative_sequences

qiime phylogeny fasttree --i-alignment masked_aligned_representative_sequences.qza --o-tree unrooted_tree

qiime phylogeny midpoint-root --i-tree unrooted_tree.qza --o-rooted-tree rooted_tree

#Generate alpha/beta diversity measures at 41000 sequences/sample
#Also generates PCoA plots automatically
qiime diversity core-metrics-phylogenetic --i-phylogeny rooted_tree.qza --i-table filtered_table.qza --p-sampling-depth 41000 --output-dir diversity_41000 --m-metadata-file sequence_data/METADATA.txt

#Test for between-group differences
qiime diversity alpha-group-significance --i-alpha-diversity diversity_41000/faith_pd_vector.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization diversity_41000/alpha_PD_significance

qiime diversity alpha-group-significance --i-alpha-diversity diversity_41000/shannon_vector.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization diversity_41000/alpha_shannon_significance

qiime diversity beta-group-significance --i-distance-matrix diversity_41000/bray_curtis_distance_matrix.qza --m-metadata-file sequence_data/METADATA.txt --m-metadata-column bee_type --o-visualization diversity_41000/beta_bray_beetype_significance

#Alpha rarefaction curves show taxon accumulation as a function of sequence depth
qiime diversity alpha-rarefaction --i-table table.qza --p-max-depth 41000 --o-visualization diversity_41000/alpha_rarefaction.qzv --m-metadata-file sequence_data/METADATA.txt --i-phylogeny rooted_tree.qza
