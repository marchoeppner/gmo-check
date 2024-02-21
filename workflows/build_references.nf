include { GUNZIP }              from "./../modules/gunzip"
include { SAMTOOLS_FAIDX }      from "./../modules/samtools/faidx"
include { SAMTOOLS_DICT }       from "./../modules/samtools/dict"
include { BWAMEM2_INDEX }       from "./../modules/bwamem2/index"

genomes = params.references.genomes.keySet()

genome_list = []

// Get all the configured genomes
genomes.each { genome ->
    def meta = [:]
    meta.id = genome.toString()

    genome_list << tuple(meta,file(params.references.genomes[genome].url, checkIfExists: true ))
}

ch_genomes = Channel.fromList(genome_list)

// Workflow starts here
workflow BUILD_REFERENCES {

    main:

    // Check if any of the fasta files are gzipped
    ch_genomes.branch {
        compressed: it[1].toString().contains(".gz")
        uncompressed: !it[1].toString().contains(".gz")
    }.set { ch_genomes_branched }

    // unzip all the compressed fasta files
    GUNZIP(
        ch_genomes_branched.compressed
    )
    
    // merge all fasta files back into one channel
    ch_fasta = ch_genomes_branched.uncompressed.mix(GUNZIP.out.gunzip)

    // Index the fasta file(s)
    SAMTOOLS_FAIDX(
        ch_fasta
    )

    // Create a sequence dictionary for the fasta file(s)
    SAMTOOLS_DICT(
        ch_fasta
    )

    // Create the BWA2 index for the fasta file(s)
    BWAMEM2_INDEX(
        ch_fasta
    )
    
}