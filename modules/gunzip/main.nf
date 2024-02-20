process GUNZIP {

    tag "${zipped}"

    label 'medium_serial'

    conda 'sed=4.7'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'nf-core/ubuntu:20.04' }"

    input:
    path(zipped)

    output:
    path(unzipped), emit: uncompressed
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
