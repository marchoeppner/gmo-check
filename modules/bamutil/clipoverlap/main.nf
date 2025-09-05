process BAMUTIL_CLIPOVERLAP {
    tag "$meta.sample_id"
    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bamutil:1.0.15--h2e03b76_1' :
        'quay.io/biocontainers/bamutil:1.0.15--h2e03b76_1' }"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*clipped.bam")   , emit: bam
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.sample_id}"
    """
    bam \\
        clipOverlap \\
        --in $bam \\
        --out ${prefix}.clipped.bam \\
        $args 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bamutil: \$( echo \$( bam trimBam 2>&1 ) | sed 's/^Version: //;s/;.*//' )
    END_VERSIONS
    """
}
