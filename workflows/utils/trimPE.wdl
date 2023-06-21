version 1.0

task trimmomaticPE {
    
    input {
        Array[File] paired_fastq
        File adapterPE
    }

    parameter_meta {
        paired_fastq: "Paired-end fastq file downloaded from SRA"
        adapterPE: "Paired-end adapter fasta file for Trimmomatic."
    }
    
    String AT_R1 = basename(paired_fastq[0], ".fastq")
    String AT_R2 = basename(paired_fastq[1], ".fastq")

    Int memory_mb = ceil(size(paired_fastq, "MiB")) + 5000
    Int disk_size_gb = ceil(size(paired_fastq, "GiB")) * 2
    
    command {
        echo "PAIRED"
        trimmomatic PE -threads 8 ${paired_fastq[0]} ${paired_fastq[1]} ${AT_R1}_AT.fastq ${AT_R1}_unpaired.fastq ${AT_R2}_AT.fastq ${AT_R2}_unpaired.fastq ILLUMINACLIP:${adapterPE}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36
    }
    
    output {
        File stat_file = stderr()
        Array[File] trimmed_fastqs = ["${AT_R1}_AT.fastq", "${AT_R2}_AT.fastq", "${AT_R1}_unpaired.fastq", "${AT_R2}_unpaired.fastq"]
    }
        
    runtime {
        docker: "akm0001/mamba-trimmomatic"
        memory: "~{memory_mb} MiB"
        disks: "local-disk ~{disk_size_gb} HDD"
    }
}
