
include { BWAMEM2_INDEX }       from "./../modules/bwamem2/index"
include { SAMTOOLS_FAIDX }      from "./../modules/samtools/faidx"
include { SAMTOOLS_DICT }       from "./../modules/samtools/dict"
include { GUNZIP }              from "./../modules/gunzip"

genomes = params.references.genomes.keySet()

genome_list = []

genomes.each { genome ->
    def meta = [:]
    meta.name = genome.toString()

    genome_list << tuple(meta,file(params.references.genomes[genome].url, checkIfExists: true ))
}

ch_genomes = Channel.fromList(genome_list)

workflow BUILD_REFERENCES {

    main:

    SAMTOOLS_FAIDX(
        ch_genomes
    )
}