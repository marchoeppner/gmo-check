include { BWAMEM2_MEM }             from './../../modules/bwamem2/mem'
include { SAMTOOLS_MERGE }          from './../../modules/samtools/merge'
include { SAMTOOLS_MARKDUP }        from './../../modules/samtools/markdup'
include { SAMTOOLS_INDEX }          from './../../modules/samtools/index'
include { SAMTOOLS_AMPLICONCLIP }   from './../../modules/samtools/ampliconclip'
include { FREEBAYES }               from './../../modules/freebayes'

ch_versions = Channel.from([])
ch_qc = Channel.from([])

workflow BWAMEM2_WORKFLOW {

    take:
    reads
    fasta
    bed

    main:

    BWAMEM2_MEM(
        reads,
        fasta
    )

    ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions)

    bam_mapped = BWAMEM2_MEM.out.bam.map { meta, bam ->
        new_meta = [:]
        new_meta.sample_id = meta.sample_id
        def groupKey = meta.sample_id
        tuple(groupKey, new_meta, bam)
    }.groupTuple(by: [0, 1]).map { g, new_meta, bam -> [ new_meta, bam ] }

    bam_mapped.branch {
        single:   it[1].size() == 1
        multiple: it[1].size() > 1
    }.set { bam_to_merge }

    SAMTOOLS_MERGE(bam_to_merge.multiple)
    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions)

    SAMTOOLS_INDEX(SAMTOOLS_MERGE.out.bam.mix(bam_to_merge.single))
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    SAMTOOLS_AMPLICONCLIP(
        SAMTOOLS_INDEX.out.bam,
        bed
    )
    ch_versions = ch_versions.mix(SAMTOOLS_AMPLICONCLIP.out.versions)

    FREEBAYES(
        SAMTOOLS_AMPLICONCLIP.out.bam,
        fasta
    )
    ch_versions = ch_versions.mix(FREEBAYES.out.versions)

    emit:
    qc = ch_qc
    versions = ch_versions
    vcf = FREEBAYES.out.vcf

}
