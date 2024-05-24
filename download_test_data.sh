#!/usr/bin/env bash

# Author: Jeffrey Grover
# Created: 2024-05-18
# Purpose: Download the D. melanogaster test data from DOI: 10.1101/gr.108662.110
# Requirements: apptainer, gzip

# Dump the relevant fastqs with fasterq-dump
apptainer run docker://quay.io/biocontainers/sra-tools:3.1.0--h4304569_1 \
  fasterq-dump \
    -O 00_fastq \
    SRR031708 SRR031714 SRR031718 SRR031724

# gzip the files
gzip 00_fastq/*.fastq