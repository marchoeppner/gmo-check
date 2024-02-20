include { VSEARCH_FASTQMERGE }      from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTXUNIQUES }    from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }     from './../../modules/vsearch/fastqfilter'
include { BLAST_BLASTN }            from './../../modules/blast/blastn'
include { PTRIMMER }                from "./../../modules/ptrimmer"

ch_versions = Channel.from([])

workflow VSEARCH_WORKFLOW {
    take:
    reads
    db
    amplicon_txt

    main:

    // Remove PCR adapter sites from reads
    PTRIMMER(
        reads,
        amplicon_txt
    )
    ch_versions = ch_versions.mix(PTRIMMER.out.versions)

    VSEARCH_FASTQMERGE(
        PTRIMMER.out.reads
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
