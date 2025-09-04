include { VSEARCH_FASTQMERGE }      from './../../modules/vsearch/fastqmerge'
include { VSEARCH_FASTXUNIQUES }    from './../../modules/vsearch/fastxuniques'
include { VSEARCH_FASTQFILTER }     from './../../modules/vsearch/fastqfilter'
include { BLAST_BLASTN }            from './../../modules/blast/blastn'
include { PTRIMMER }                from './../../modules/ptrimmer'
include { BLAST_TO_REPORT }         from './../../modules/helper/blast_to_report'
include { CAT_FASTQ }               from './../../modules/cat_fastq'

workflow VSEARCH_WORKFLOW {

    take:
    reads
    db
    amplicon_txt
    rules

    main:

    ch_versions = Channel.from([])
    ch_reports  = Channel.from([])

    // Remove PCR adapter sites from reads
    PTRIMMER(
        reads,
        amplicon_txt
    )
    ch_versions = ch_versions.mix(PTRIMMER.out.versions)

    // group and branch trimmed reads by sample to find multi-lane data set
    PTRIMMER.out.reads.map { m,r -> 
        def newMeta = [:]
        newMeta.sample_id = m.sample_id
        newMeta.single_end = m.single_end
        tuple(newMeta,r)
    }.groupTuple().branch { meta, fastqs ->
        single: fastqs.size() == 1
            return [ meta, fastqs.flatten()]
        multi: fastqs.size() > 1
            return [ meta, fastqs.flatten()]
    }.set { ch_reads_trimmed }

    // Concatenate samples with multiple files (multi-lane)
    CAT_FASTQ(
        ch_reads_trimmed.multi
    )
    ch_versions = ch_versions.mix(CAT_FASTQ.out.versions)

    ch_reads_concat = ch_reads_trimmed.single.mix(CAT_FASTQ.out.reads)

    // Find which emissions are single-end and which are paired-end
    ch_reads_concat.branch { m,r ->
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
