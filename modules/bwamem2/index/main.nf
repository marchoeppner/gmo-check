process BWAMEM2_INDEX {
    tag "${meta.id}"

    label 'medium_serial'

    conda 'bioconda::samtools=1.19.2 bioconda::bwa-mem2=2.2.1'
    container 'quay.io/biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:2cdf6bf1e92acbeb9b2834b1c58754167173a410-0'

    publishDir "${params.outdir}/gmo-check/${meta.id}", mode: 'copy'

    input:
    tuple val(meta), path(fasta)

    output:
    path('*'), emit: bwa_index
    path("versions.yml"), emit: versions

    script:
    """
    bwa-mem2 index $fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
