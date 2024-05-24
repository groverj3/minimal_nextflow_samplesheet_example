#!/usr/bin/env bash

# Author: Jeffrey Grover
# Created: 2024-05-18
# Purpose: Download the D. melanogaster transcriptome from ensembl and index with salmon
# Requirements: wget and apptainer

# Download the D. melanogaster transcriptome
wget -P ./references https://ftp.ensemblgenomes.ebi.ac.uk/pub/metazoa/release-59/fasta/drosophila_melanogaster/cds/Drosophila_melanogaster.BDGP6.46.cds.all.fa.gz

# Index the genome
# Uses a docker container from biocontainers for salmon
apptainer run docker://quay.io/biocontainers/salmon:1.10.3--hecfa306_0 \
  salmon index \
    -t ./references/Drosophila_melanogaster.BDGP6.46.cds.all.fa.gz \
    -i ./references/Drosophila_melanogaster.BDGP6.46.cds.all_index
