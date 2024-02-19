include { VSEARCH_FASTQMERGE }      from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTXUNIQUES }    from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }     from './../../modules/vsearch/fastqfilter'
include { BLAST_BLASTN }            from './../../modules/blast/blastn'

ch_versions = Channel.from([])

workflow VSEARCH_WORKFLOW {
    take:
    reads
    db

    main:

    VSEARCH_FASTQMERGE(
        reads
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQMERGE.out.versions)

    VSEARCH_FASTQFILTER(
        VSEARCH_FASTQMERGE.out.fastq
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQFILTER.out.versions)

    VSEARCH_FASTXUNIQUES(
        VSEARCH_FASTQFILTER.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTXUNIQUES.out.versions)

    BLAST_BLASTN(
        VSEARCH_FASTXUNIQUES.out.fasta,
        db
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

    emit:
    versions = ch_versions
    results = BLAST_BLASTN.out.results
}
