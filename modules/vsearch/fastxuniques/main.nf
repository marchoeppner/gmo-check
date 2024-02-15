process VSEARCH_FASTXUNIQUES {

    publishDir "${params.outdir}/VSEARCH", mode: 'copy'

    label 'short_serial'

    conda 'bioconda::vsearch=2.27.0'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0 :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    input:
    tuple val(meta),path(fa)

    output:
    tuple val(meta),path(derep), emit: fasta

    script:
    derep = fa.getBaseName() + ".unique.fasta"

    """
    vsearch -fastq_uniques $fa -sizeout -relabel Unique -fastaout $derep

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | sed -e "s/vsearch //g" -e "s/,.*//")
    END_VERSIONS
    """
}