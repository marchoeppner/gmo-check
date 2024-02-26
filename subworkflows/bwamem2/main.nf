include { BWAMEM2_MEM }             from './../../modules/bwamem2/mem'
include { SAMTOOLS_MERGE }          from './../../modules/samtools/merge'
include { SAMTOOLS_MARKDUP }        from './../../modules/samtools/markdup'
include { SAMTOOLS_INDEX }          from './../../modules/samtools/index'
include { SAMTOOLS_AMPLICONCLIP }   from './../../modules/samtools/ampliconclip'
include { FREEBAYES }               from './../../modules/freebayes'
include { VCF_TO_REPORT }           from './../../modules/helper/vcf_to_report'
include { RULES_TO_BED }            from './../../modules/helper/rules_to_bed'
include { BEDTOOLS_COVERAGE }       from './../../modules/bedtools/coverage'

ch_versions = Channel.from([])
ch_qc       = Channel.from([])
ch_reports  = Channel.from([])

workflow BWAMEM2_WORKFLOW {
    take:
    reads
    fasta
    bed
    rules

    main:

    // Convert the rules to a list of regions
    RULES_TO_BED(
        rules
    )
    ch_bed = RULES_TO_BED.out.bed.collect()

    // read alignment with BWA2
    // This already includes sorting and fixing mate information
    BWAMEM2_MEM(
        reads,
        fasta
    )

    ch_versions = ch_versions.mix(BWAMEM2_MEM.out.versions)

    // Group BAM files by sample, in case of multi-lane setup
    bam_mapped = BWAMEM2_MEM.out.bam.map { meta, bam ->
        newMeta = [:]
        newMeta.sample_id = meta.sample_id
        def groupKey = meta.sample_id
        tuple(groupKey, newMeta, bam)
    }.groupTuple(by: [0, 1]).map { g, newMeta, bam -> [ newMeta, bam ] }

    // Check if any of the samples have more than one BAM file (i.e. multi-lane)
    bam_mapped.branch {
        single:   it[1].size() == 1
        multiple: it[1].size() > 1
    }.set { bam_to_merge }

    // Merge BAM files by sample, if any
    SAMTOOLS_MERGE(bam_to_merge.multiple)
    ch_versions = ch_versions.mix(SAMTOOLS_MERGE.out.versions)

    // Index all BAM files
    SAMTOOLS_INDEX(SAMTOOLS_MERGE.out.bam.mix(bam_to_merge.single))
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions)

    // Mask out primer binding sites
    SAMTOOLS_AMPLICONCLIP(
        SAMTOOLS_INDEX.out.bam,
        ch_bed
    )
    ch_versions = ch_versions.mix(SAMTOOLS_AMPLICONCLIP.out.versions)

    // Call variants using Freebayes
    FREEBAYES(
        SAMTOOLS_AMPLICONCLIP.out.bam,
        fasta,
        ch_bed
    )
    ch_versions = ch_versions.mix(FREEBAYES.out.versions)

    // Get coverage or target region(s)
    BEDTOOLS_COVERAGE(
        SAMTOOLS_AMPLICONCLIP.out.bam,
        ch_bed
    )

    ch_variants_with_cov = FREEBAYES.out.vcf.join(BEDTOOLS_COVERAGE.out.report)

    // Obtain results from VCF file using rules
    VCF_TO_REPORT(
        ch_variants_with_cov,
        rules
    )

    ch_reports = ch_reports.mix(VCF_TO_REPORT.out.json)

    emit:
    qc          = ch_qc
    versions    = ch_versions
    vcf         = FREEBAYES.out.vcf
    reports     = ch_reports
    bam         = SAMTOOLS_AMPLICONCLIP.out.bam
}
