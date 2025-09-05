process JSON_TO_XLSX {
    tag 'All'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pbiotools:4.0.2--pyhdfd78af_0' :
        'quay.io/biocontainers/pbiotools:4.0.2--pyhdfd78af_0' }"

    input:
    path(jsons)

    output:
    path(excel), emit: xlsx

    script:
    excel = params.run_name + '.xlsx'

    """
    reports_to_xls_v2.py --output $excel
    """
}
