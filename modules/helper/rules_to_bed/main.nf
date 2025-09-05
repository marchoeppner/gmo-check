process RULES_TO_BED {

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.19--pyhdfd78af_0' :
        'quay.io/biocontainers/multiqc:1.19--pyhdfd78af_0' }"
        
    input:
    path(json)

    output:
    path(bed), emit: bed

    script:
    bed = 'rules.txt'

    """
    rules_to_bed.py --json $json --output $bed
    """
}
