version 1.0

task download_fastqs {
    
    input {
        String run_accession
    }
    
    command {
        fasterq-dump "${run_accession}"
    }
    
    output {
        Array[File] fastqs = glob("*.fastq")
    }
    
    parameter_meta {
        run_accession : {
            help : "SRA run accession",
            suggestions: ["SRR12548227", "SRR17822879"]
        }
    }
    runtime {
        docker: "akm0001/mamba-sra-tools"
        memory: "16 GiB"
    }
}

task trimmomaticPE {
    
    input {
        Array[File] paired_fastq
        File adapterPE
    }
    
    String AT_R1 = basename(paired_fastq[0], ".fastq")
    String AT_R2 = basename(paired_fastq[1], ".fastq")

    Int memory_mb = ceil(size(paired_fastq, "MiB")) + 5000
    Int disk_size_gb = ceil(size(paired_fastq, "GiB")) + 5
    
    command {
        echo "PAIRED"
        trimmomatic PE -threads 8 ${paired_fastq[0]} ${paired_fastq[1]} ${AT_R1}_AT.fastq ${AT_R1}_unpaired.fastq ${AT_R2}_AT.fastq ${AT_R2}_unpaired.fastq ILLUMINACLIP:${adapterPE}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    }
    
    output {
        File stat_file = stdout()
        Array[File] trimmed_fastqs = ["${AT_R1}_AT.fastq", "${AT_R2}_AT.fastq", "${AT_R1}_unpaired.fastq", "${AT_R2}_unpaired.fastq"]
    }
    
    parameter_meta {
        adapterPE : {
            help : "Paired-end adapter fasta file",
        }
    }
    
    runtime {
        docker: "akm0001/mamba-trimmomatic"
        memory: "~{memory_mb} MiB"
        disks: "local-disk ~{disk_size_gb} HDD"
    }
}

task trimmomaticSE {

    input {
        Array[File] single_fastq
        File adapterSE
    }
    
    String AT_SE = basename(single_fastq[0], ".fastq")

    Int memory_mb = ceil(size(single_fastq, "MiB")) + 5000
    Int disk_size_gb = ceil(size(single_fastq, "GiB")) + 5
    
    command {
        echo "SINGLE"
        trimmomatic SE -threads 8 ${single_fastq[0]} ${AT_SE}_AT.fastq ILLUMINACLIP:${adapterSE}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    }
    
    output {
        File stat_file = stdout()
        Array[File] trimmed_fastqs = [ "${AT_SE}_AT.fastq" ]
    }
    
    parameter_meta {
        adapterSE : {
            help : "Single-end adapter fasta file",
        }
    }
    
    runtime {
        docker: "akm0001/mamba-trimmomatic"
        memory: "~{memory_mb} MiB"
        disks: "local-disk ~{disk_size_gb} HDD"
    }

}

workflow main {
    
    input {
        Array[String] sra_run_accession
    }
    
    scatter (runID in sra_run_accession) {
        
        call download_fastqs {
            input: run_accession = runID
        }      

        Int num_fastq = length(download_fastqs.fastqs)

        if (num_fastq == 2) {
            call trimmomaticPE {
                input: paired_fastq = download_fastqs.fastqs,
            }
        }    

        if (num_fastq == 1) {
            call trimmomaticSE {
                input : single_fastq = download_fastqs.fastqs,
            }
        }
    }

    meta {
        desc: "Takes a list of SRA run accessions and runs fasterq-dump and trimmomatic."
        author: "Anand Maurya"
    }
}