#!/bin/bash

#The other two scripts must be run first! (fetchFastq.sh then assemblePairs.sh)

#This command imports the FASTQ files into a QIIME artifact
qiime tools import --type 'SampleData[SequencesWithQuality]' --input-path sequence_data/merged_reads/ --output-path reads --source-format CasavaOneEightSingleLanePerSampleDirFmt

#Using DADA2 to analyze quality scores of 10 random samples
qiime dada2 plot-qualities --p-n 10 --i-demultiplexed-seqs reads.qza --o-visualization qual_viz

#Denoising with DADA2. Using quality score visualizations, you can choose trunc-len (note: sequences < trunc-len in length are discarded!) and trim-left
qiime dada2 denoise --i-demultiplexed-seqs reads.qza --o-table table --o-representative-sequences representative_sequences --p-trunc-len 250 --p-trim-left 0 --verbose

#This visualization shows us the sequences/sample spread
qiime feature-table summarize --i-table table.qza --o-visualization table_summary

#Filter out sequences with few samples
qiime feature-table filter-samples --i-table table.qza --p-min-frequency 5000 --o-filtered-table filtered_table

qiime feature-table summarize --i-table filtered_table.qza --o-visualization filtered_table_summary

#QIIME group has a 515f 806r 99% pre-clustered GreenGenes database
wget https://data.qiime2.org/2.0.6/common/gg-13-8-99-515-806-nb-classifier.qza

#Classify against it with Naive Bayes
qiime feature-classifier classify --i-classifier gg-13-8-99-515-806-nb-classifier.qza --i-reads representative_sequences.qza --o-classification taxonomy

#Generates a taxon table
qiime taxa tabulate --i-data taxonomy.qza --o-visualization taxonomy

#Steps for generating a phylogenetic tree
qiime alignment mafft --i-sequences representative_sequences.qza --o-alignment aligned_representative_sequences

qiime alignment mask --i-alignment aligned_representative_sequences.qza --o-masked-alignment masked_aligned_representative_sequences

qiime phylogeny fasttree --i-alignment masked_aligned_representative_sequences.qza --o-tree unrooted_tree

qiime phylogeny midpoint-root --i-tree unrooted_tree.qza --o-rooted-tree rooted_tree

#Generate alpha/beta diversity measures at 41000 sequences/sample
qiime diversity core-metrics --i-phylogeny rooted_tree.qza --i-table filtered_table.qza --p-sampling-depth 41000 --output-dir diversity_41000

#Test for between-group differences
qiime diversity alpha-group-significance --i-alpha-diversity diversity_41000/faith_pd_vector.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization diversity_41000/alpha_PD_significance

qiime diversity alpha-group-significance --i-alpha-diversity diversity_41000/shannon_vector.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization diversity_41000/alpha_shannon_significance

qiime diversity beta-group-significance --i-distance-matrix diversity_41000/bray_curtis_distance_matrix.qza --m-metadata-file sequence_data/METADATA.txt --m-metadata-category BeeType --o-visualization diversity_41000/beta_bray_beetype_significance

#The ubiquitous PCoA plots
qiime emperor plot --i-pcoa diversity_41000/bray_curtis_pcoa_results.qza --o-visualization diversity_41000/pcoa_bray --m-metadata-file sequence_data/METADATA.txt

qiime emperor plot --i-pcoa diversity_41000/weighted_unifrac_pcoa_results.qza --o-visualization diversity_41000/pcoa_wunifrac --m-metadata-file sequence_data/METADATA.txt

#Taxa bar plots
qiime taxa barplot --i-table filtered_table.qza --i-taxonomy taxonomy.qza --m-metadata-file sequence_data/METADATA.txt --o-visualization taxa-bar-plots
