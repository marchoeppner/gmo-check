process FREEBAYES {
    tag "${meta.sample_id}"

    publishDir "${params.outdir}/Freebayes", mode: 'copy'

    label 'medium_serial'

    conda 'bioconda::freebayes=1.3.6'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/freebayes:1.3.6--hb0f3ef8_7' :
        'quay.io/biocontainers/freebayes:1.3.6--hb0f3ef8_7' }"

    input:
    tuple val(meta), path(bam), path(bai)
    path(fasta)
    
    output:
    tuple val(meta), path(vcf), emit: vcf
    path("versions.yml"), emit: versions

    script:
    vcf = meta.sample_id + '.vcf'

    """
    freebayes -f $fasta \
        --genotype-qualities \
        --pooled-continuous \
        --min-alternate-count ${params.freebayes_min_alternate_count} \
        --min-alternate-fraction ${params.freebayes_min_alternate_frac} \
        $bam > $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        freebayes: \$(echo \$(freebayes --version 2>&1) | sed 's/version:\s*v//g' )
    END_VERSIONS

    """
}
