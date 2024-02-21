process BWAMEM2_INDEX {

    tag "${meta.genome}"

    label 'medium_serial'

    publishDir "${params.outdir}/${meta.genome}", mode 'copy'

    input:
    tuple val(meta),path(fasta)

    output:
    //path('*'), emit: bwa_index
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
