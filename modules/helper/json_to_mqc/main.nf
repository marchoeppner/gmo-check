process JSON_TO_MQC {
    tag 'All'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0' }"

    input:
    path(jsons)

    output:
    path("*_mqc.tsv"), emit: mqc

    script:

    '''
    reports_to_table.py
    '''
}
