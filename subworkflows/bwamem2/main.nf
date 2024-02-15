include { BWAMEM2_MEM }         from "./../modules/bwamem2/mem/main"
include { SAMTOOLS_MERGE }      from "./../modules/samtools/merge/main"
include { SAMTOOLS_MARKDUP }    from "./../modules/samtools/markdup/main"
include { SAMTOOLS_INDEX }      from "./../modules/samtools/index/main"

ch_versions = Channel.from([])

workflow BWAMEM2_WORKFLOW {

    take:
    reads
    reference

    main:

    BWAMEM2_MEM(
        reads,
        reference
    )

    ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions)

    bam_mapped = BWAMEM2_MEM.out.bam.map { meta, bam ->
        new_meta = [:]
        new_meta.sample_id = meta.sample_id
        def groupKey = meta.sample_id
        tuple( groupKey, new_meta, bam)
    }.groupTuple(by: [0,1]).map { g ,new_meta ,bam -> [ new_meta, bam ] }
            
    bam_mapped.branch {
        single:   it[1].size() == 1
        multiple: it[1].size() > 1
    }.set { bam_to_merge }

    SAMTOOLS_MERGE( bam_to_merge.multiple )

    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions)

    SAMTOOLS_INDEX(SAMTOOLS_MERGE.out.bam.mix( bam_to_merge.single ))

    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    SAMTOOLS_MARKDUP(
        SAMTOOLS_INDEX.out.bam
    )
    ch_versions = ch_versions.mix(SAMTOOLS_MARKDUP.out.versions)

    FREEBAYES(
        SAMTOOLS_MARKDUP.out.bam,
        reference
    )
    ch_versions = ch_versions.mix(FREEBAYES.out.versions)

    emit:
    versions = ch_versions
    vcf = FREEBAYES.out.vcf
    
}
