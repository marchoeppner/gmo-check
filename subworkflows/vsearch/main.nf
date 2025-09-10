include { VSEARCH_FASTQMERGE }          from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTXUNIQUES }        from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }         from './../../modules/vsearch/fastqfilter'
include { VSEARCH_FASTQFILTER_READS }   from './../../modules/vsearch/fastqfilter_reads'
include { BLAST_BLASTN }                from './../../modules/blast/blastn'
include { BLAST_TO_REPORT }             from './../../modules/helper/blast_to_report'

workflow VSEARCH_WORKFLOW {

    take:
    reads
    db
    rules

    main:
    ch_versions = Channel.from([])
    ch_reports  = Channel.from([])

    /*
    Quality filtr fastq prior to merging
    */
    VSEARCH_FASTQFILTER_READS(
        reads
    )

    // Find which emissions are single-end and which are paired-end
    VSEARCH_FASTQFILTER_READS.out.reads.branch { m,r ->
        single: m.single_end 
        paired: !m.single_end
    }.set { ch_reads_by_layout }

    // Merge PE files
    VSEARCH_FASTQMERGE(
        ch_reads_by_layout.paired.map { m,r -> [ m, r[0],r[1]]}
    )
    ch_versions = ch_versions.mix(VSEARCH_FASTQMERGE.out.versions)

    // All reads - either merged or single-end as is. 
    ch_reads_merged = ch_reads_by_layout.single.mix(VSEARCH_FASTQMERGE.out.fastq)

    // Files merged reads using static parameters
    // This is not ideal and could be improved!
    VSEARCH_FASTQFILTER(
        ch_reads_merged
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
        BLAST_BLASTN.out.results.filter { it[1].size() > 0 },
        rules
    )
    ch_reports = ch_reports.mix(BLAST_TO_REPORT.out.json)

    emit:
    versions = ch_versions
    results = BLAST_BLASTN.out.results
    reports = ch_reports
}
