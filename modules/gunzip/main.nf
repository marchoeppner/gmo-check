process GUNZIP {

    tag "${meta.genome}"

    label 'medium_serial'

    publishDir "${params.outdir}/${meta.genome}", mode: 'copy'

    conda 'sed=4.7'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    tuple val(meta),path(zipped)

    output:
    tuple val(meta),path(unzipped), emit: gunzip
    path("versions.yml"), emit: versions

    script:
    unzipped = zipped.getBaseName()

    """
    gunzip -c $zipped > $unzipped

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gunzip: \$(echo \$(gunzip --version 2>&1) | sed 's/^.*(gzip) //; s/ Copyright.*\$//')
    END_VERSIONS

    """
}
