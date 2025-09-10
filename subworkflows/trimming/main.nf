include { PTRIMMER }                from './../../modules/ptrimmer'
include { CAT_FASTQ }               from './../../modules/cat_fastq'
include { FASTP }                   from './../../modules/fastp'


workflow TRIMMING {

    take:
    reads
    amplicon_txt

    main:
    
    ch_versions = Channel.from([])
    ch_qc       = Channel.from([])

    // trim reads using fastP in automatic mode and with overlap correction
    FASTP(
        reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    ch_qc = ch_qc.mix(FASTP.out.json)

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

    emit:
    versions = ch_versions
    trimmed = ch_reads_concat
    qc = ch_qc

}