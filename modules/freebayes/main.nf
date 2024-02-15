process FREEBAYES {

    publishDir "${params.outdir}/Freebayes", mode: 'copy'

    label 'medium_serial'

    conda 'bioconda::freebayes=1.3.6'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/freebayes:1.3.6--hb0f3ef8_7' :
        'quay.io/biocontainers/freebayes:1.3.6--hb0f3ef8_7' }"


}