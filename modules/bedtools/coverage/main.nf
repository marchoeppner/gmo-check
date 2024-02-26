process BEDTOOLS_COVERAGE {
    publishDir "${params.outdir}/${meta.sample_id}/BEDTOOLS", mode: 'copy'

    label 'short_parallel'

    tag "${meta.sample_id}"

    conda 'bioconda::bedtools=2.31.1'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.1--hf5e1c6e_0' :
        'quay.io/biocontainers/bedtools:2.31.1--hf5e1c6e_0' }"

    input:
    tuple val(meta),path(bam),path(bai)
    path(bed)

    output:
    tuple val(meta), path(coverage), emit: report
    path('versions.yml'), emit: versions

    script:
    coverage = meta.sample_id + ".bedcov.txt"
    
    """
    coverageBed -a $bed -b $bam > $coverage

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(echo \$(bedtools --version 2>&1) | sed 's/^.*bedtools v//' ))
    END_VERSIONS

    """
}
