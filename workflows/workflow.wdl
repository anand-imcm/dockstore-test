version 1.0

## The WDL script performs the following steps to process the SRA data:
## Download SRA Data: The script uses fasterq-dump to download the SRA data corresponding to the provided run accessions.
## Quality Trimming: The downloaded FASTQ files are processed using trimmomatic to perform quality trimming and filtering of the reads.

import "./utils/fetchSRA.wdl" as fetchSRA
import "./utils/trimPE.wdl" as trimPE
import "./utils/trimSE.wdl" as trimSE

workflow main {
    
    input {
        Array[String] sra_run_accession
    }

    parameter_meta {
        sra_run_accession: "List of SRA run accession identifiers"        
    }

    scatter (runID in sra_run_accession) {
        
        call fetchSRA.download_fastqs {
            input: run_accession = runID
        }      

        Int num_fastq = length(download_fastqs.fastqs)

        if (num_fastq == 2) {
            call trimPE.trimmomaticPE {
                input: paired_fastq = download_fastqs.fastqs,
            }
        }    

        if (num_fastq == 1) {
            call trimSE.trimmomaticSE {
                input : single_fastq = download_fastqs.fastqs,
            }
        }
    
    }

    Array[File] fastqs = flatten(download_fastqs.fastqs)
    Array[File] trimmed_fastqs_SE = flatten(select_all(trimmomaticSE.trimmed_fastqs))
    Array[File] trimmed_fastqs_PE = flatten(select_all(trimmomaticPE.trimmed_fastqs))
    Array[File] stat_file_SE = select_all(trimmomaticSE.stat_file)
    Array[File] stat_file_PE = select_all(trimmomaticPE.stat_file)

    output {
        Array[File] raw_fastq = fastqs
        Array[File]? trim_stats_SE = stat_file_SE
        Array[File]? trim_stats_PE = stat_file_PE
        Array[File]? trimmed_fastqs_SE_out = trimmed_fastqs_SE
        Array[File]? trimmed_fastqs_PE_out = trimmed_fastqs_PE
    }

    meta {
        desc: "Takes a list of SRA run accessions and runs fasterq-dump and trimmomatic."
        author: "Anand Maurya"
    }
}