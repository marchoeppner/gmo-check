process BLAST_TO_REPORT {
    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(blast)
    path(rules)

    output:
    tuple val(meta), path(report), emit: json

    script:
    report = blast.getBaseName() + '.report.json'

    """
    analyze_blast.py \
    --blast $blast \
    --json $rules \
    --sample ${meta.sample_id} \
    --output $report
    """
}
