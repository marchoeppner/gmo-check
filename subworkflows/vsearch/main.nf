include { VSEARCH_FASTQMERGE }      from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTXUNIQUES }    from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }     from './../../modules/vsearch/fastqfilter'
include { BLAST_BLASTN }            from './../../modules/blast/blastn'
include { PTRIMMER }                from "./../../modules/ptrimmer"
include { BLAST_TO_REPORT }         from "./../../modules/helper/blast_to_report"

ch_versions = Channel.from([])

workflow VSEARCH_WORKFLOW {
    take:
    reads
    db
    amplicon_txt
    rules

    main:

    // Remove PCR adapter sites from reads
    PTRIMMER(
        reads,
        amplicon_txt
    )
    ch_versions = ch_versions.mix(PTRIMMER.out.versions)

    // Merge PE files
    VSEARCH_FASTQMERGE(
        PTRIMMER.out.reads
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQMERGE.out.versions)

    // Files merged reads using static parameters
    // This is not ideal and could be improved!
    VSEARCH_FASTQFILTER(
        VSEARCH_FASTQMERGE.out.fastq
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQFILTER.out.versions)

    // Reduce reads into unique sequences
    VSEARCH_FASTXUNIQUES(
        VSEARCH_FASTQFILTER.out.fasta
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTXUNIQUES.out.versions)

    // Blast unique amplicon sequences
    BLAST_BLASTN(
        VSEARCH_FASTXUNIQUES.out.fasta,
        db
    )
    ch_versions = ch_versions.mix(BLAST_BLASTN.out.versions)

    // Check if a positive result is found
    BLAST_TO_REPORT(
        BLAST_BLASTN.out.results.filter{ it[1].size() > 0 },
        rules
    )
    emit:
    versions = ch_versions
    results = BLAST_BLASTN.out.results
}
