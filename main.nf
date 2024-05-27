#!/usr/bin/env nextflow

/*
Author: Jeffrey Grover
Created: 2024-05-18
Purpose: A minimal nextflow example that reads sample metadata from a
samplesheet and runs a small RNAseq workflow.
*/

// Input parameters which can be overwritten with command line options at run-time.
// All get a sensible default.
params.salmon_ref = "$baseDir/references/Drosophila_melanogaster.BDGP6.46.cds.all_index"
params.outdir = "$baseDir"
params.samplesheet = "$baseDir/samplesheet.csv"
params.input_dir = "$baseDir/00_fastq/"

// Workflow definition
workflow {
    // An unnamed workflow is automatically executed when running `nextflow run`
    // If you have multiple subworkflows you can nest them inside the main workflow

    // Read samplesheet and convert to queueable channel of: sample id, paired_status, read1, read2 as a tuple
    reads_channel = channel.fromPath(params.samplesheet)
        | splitCsv(header:true)
        | map{
            // map{} applies a function to each element of a channel
            // In this case, the rows from splitCsv() are converted to a tuple based on the header 
            row -> tuple(row.sample_id, row.paired_status, file(params.input_dir + row.read1), file(params.input_dir + row.read2))
        }
    
    // Run workflow steps
    // Note that SALMON_QUANT doesn't depend on FASTQC's outputs, and therefore can be run in parallel 
    FASTQC(reads_channel)
    SALMON_QUANT(reads_channel)
}

//Workflow steps
process FASTQC {
    tag "FastQC on $sample_id" // This labels the process with the sample_id on the command line
    publishDir "${params.outdir}/01_fastqc/${sample_id}"  // Specify where to output the results, note that they will be symlinks to the {baseDir}/work directory unless you use mode: copy
    container "quay.io/biocontainers/fastqc:0.11.9--hdfd78af_1"  // Docker containers will work with Docker, Podman, Apptainer, etc.
    cpus 1  // For production workflows you probably want to also request specific amounts of other resources like memory

    input:
    tuple val(sample_id), val(paired_status), path(read1), path(read2)  // Take the values from the reads_channel

    output:
    path "*fastqc.html" // You can use emit: {name} to refer to them as inputs to another process by name
    path "*fastqc.zip"

    script:
    // Set cpus required based on paired status
    if (paired_status == "paired_end") {
        task.cpus = 2
    }

    // Run fastqc on paired or single end reads
    if (paired_status == "paired_end") {
        """
        fastqc -t $task.cpus $read1 $read2
        """
    } else if (paired_status == "single_end") {  // We could just use "else" here but I think it's best to be explicit
        """
        fastqc -t $task.cpus $read1
        """
    }
}

process SALMON_QUANT {
    tag "SALMON_QUANT on $sample_id"
    publishDir "${params.outdir}/02_salmon_quant/${sample_id}"
    container "quay.io/biocontainers/salmon:1.10.3--hecfa306_0"
    cpus 4

    input:
    tuple val(sample_id), val(paired_status), path(read1), path(read2)

    output:
    path "quant.sf"
    path "lib_format_counts.json"
    path "cmd_info.json"
    path "aux_info/"

    script:
    if (paired_status == "paired_end") {
        """
        salmon quant \
          -p $task.cpus \
          -i $params.salmon_ref \
          -l A \
          -1 $read1 \
          -2 $read2 \
          -o ./
        """
    } else if (paired_status == "single_end") {
        """
        salmon quant \
          -p $task.cpus \
          -i $params.salmon_ref \
          -l A \
          -r $read1 \
          -o ./
        """
    }
}