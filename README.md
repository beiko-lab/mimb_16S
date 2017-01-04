# MiMB_16S

### Required Software

Before running through this tutorial, you must have the following software installed:

* vsearch
* FastTree
* MAFFT
* DADA2
* scikit-learn
* scikit-bio
* QIIME2
  * The following QIIME2 plugins are required: q2-dada2, q2-alignment, q2-phylogeny, q2-taxa, q2-diversity, q2-feature-classifier, q2-feature-table, q2-types, q2-emperor, q2-composition

### Running the Scripts

Run scripts in this order:

1. fetchFastq.sh
  * This script will fetch example data and metadata from EBI (~30mins)
  * Data from Permentier *et al.*, 2016 (DOI: 10.1111/1744-7917.12381)
2. assemblePairs.sh
  * This script assembles pairs using vsearch (~15mins)
3. qiimeCommands.sh
  * This script provides the commands for an entire QIIME analysis (~30mins)
