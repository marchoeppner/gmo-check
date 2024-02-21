include { GUNZIP }              from "./../modules/gunzip"
include { SAMTOOLS_FAIDX }      from "./../modules/samtools/faidx"

genomes = params.references.genomes.keySet()

genome_list = []

genomes.each { genome ->
    def meta = [:]
    meta.id = genome.toString()

    genome_list << tuple(meta,file(params.references.genomes[genome].url, checkIfExists: true ))
}

ch_genomes = Channel.fromList(genome_list)

workflow BUILD_REFERENCES {

    main:

    ch_genomes.branch {
        compressed: it[1].toString().contains(".gz")
        uncompressed: !it[1].toString().contains(".gz")
    }.set { ch_genomes_branched }

    GUNZIP(
        ch_genomes_branched.compressed
    )
    
    ch_fasta = ch_genomes_branched.uncompressed.mix(GUNZIP.out.gunzip)

    SAMTOOLS_FAIDX(
        ch_fasta
    )
}