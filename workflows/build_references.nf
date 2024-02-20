include { BWAMEM2_INDEX }       from "./../modules/bwamem2/index"
include { GUNZIP }              from "./../modules/gunzip"

workflow BUILD_REFERENCES {

    genomes         = params.references.genomes.keys
    genome_list     = []

    genomes.each { genome -> 
        genomes_list << Channel.fromPath([ 
            [ genome: genome ],
            params.references.genomes[genome].url) 
        ]
    }
    
    ch_genomes      = Channel.fromList(genomes_list)

    ch_genomes.branch {
        compressed: it[1].contains(".gz")
        uncompressed: !it[1].contains(".gz")
    }.set { genomes_branched }

    GUNZIP(
        genomes_branched.compressed
    )

    ch_fasta        = genomes_branched.uncompressed.mix(GUNZIP.out.uncompressed)

    BWAMEM2_INDEX(
        ch_fasta
    )

}