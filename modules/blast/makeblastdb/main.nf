process BLAST_MAKEBLASTDB {
    tag "$fasta"

    publishDir "${params.outdir}/BlastDB", mode: 'copy'

    label 'short_parallel'

    conda 'bioconda::blast=2.15'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    path(fasta)

    output:
    path('*.n*'), emit: db
    path("versions.yml"), emit: versions

    script:
    def is_compressed = fasta.getExtension() == 'gz' ? true : false
    def fasta_name = is_compressed ? fasta.getBaseName() : fasta

    """
    if [ "${is_compressed}" == "true" ]; then
        gzip -c -d ${fasta} > ${fasta_name}
    fi

    makeblastdb \
        -in $fasta_name \
        -dbtype nucl \
        -out $fasta_name

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(makeblastdb -version 2>&1 | sed 's/^.*makeblastdb: //; s/ .*\$//')
    END_VERSIONS

    """
}
