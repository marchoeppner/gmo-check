process VCF_TO_REPORT {
    tag "${meta.sample_id}"

    publishDir "${params.outdir}/Reports/JSON", mode: 'copy'

    input:
    tuple val(meta), path(vcf)
    path(rules)

    output:
    tuple val(meta), path(report), emit: json

    script:
    report = vcf.getBaseName() + '.report.json'

    """
    analyze_vcf.rb -v $vcf -j $rules -s ${meta.sample_id} > $report
    """
}
