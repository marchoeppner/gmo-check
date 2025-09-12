include { PTRIMMER }                from './../../modules/ptrimmer'
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

    emit:
    versions = ch_versions
    trimmed = PTRIMMER.out.reads
    qc = ch_qc

}