process VCF_TO_REPORT {
    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pyvcf3:1.0.4--py311haab0aaa_0' :
        'quay.io/biocontainers/pyvcf3:1.0.4--py311haab0aaa_0' }"

    input:
    tuple val(meta), path(vcf), path(coverage)
    path(rules)

    output:
    tuple val(meta), path(report), emit: json

    script:
    report = vcf.getBaseName() + '.report.json'

    """
    analyze_vcf.py \
    --vcf $vcf \
    --json $rules \
    --coverage $coverage \
    --sample ${meta.sample_id} \
    --output $report
    """
}
