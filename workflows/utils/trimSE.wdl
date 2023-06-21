version 1.0

task trimmomaticSE {

    input {
        Array[File] single_fastq
        File adapterSE
    }

    parameter_meta {
        single_fastq: "Single-end fastq file downloaded from SRA"
        adapterSE: "SIngle-end adapter fasta file for Trimmomatic."
    }
    
    String AT_SE = basename(single_fastq[0], ".fastq")

    Int memory_mb = ceil(size(single_fastq, "MiB")) + 5000
    Int disk_size_gb = ceil(size(single_fastq, "GiB")) * 2
    
    command {
        echo "SINGLE"
        trimmomatic SE -threads 8 ${single_fastq[0]} ${AT_SE}_AT.fastq ILLUMINACLIP:${adapterSE}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    }
    
    output {
        File stat_file = stderr()
        Array[File] trimmed_fastqs = [ "${AT_SE}_AT.fastq" ]
    }
    
    runtime {
        docker: "akm0001/mamba-trimmomatic"
        memory: "~{memory_mb} MiB"
        disks: "local-disk ~{disk_size_gb} HDD"
    }

}