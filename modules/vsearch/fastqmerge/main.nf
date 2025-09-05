process VSEARCH_FASTQMERGE {
    tag "${meta.sample_id}"

    label 'short_serial'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vsearch:2.27.0--h6a68c12_0' :
        'quay.io/biocontainers/vsearch:2.27.0--h6a68c12_0' }"

    input:
    tuple val(meta), path(fwd), path(rev)

    output:
    tuple val(meta), path(merged), emit: fastq
    path("versions.yml"), emit: versions

    script:
    merged = meta.sample_id + '.merged.fastq'

    """
    vsearch --fastq_merge $fwd --reverse $rev \
    --threads ${task.cpus} \
    --fastqout $merged \
    --fastq_eeout

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        vsearch: \$(vsearch --version 2>&1 | head -n 1 | sed 's/vsearch //g' | sed 's/,.*//g' | sed 's/^v//' | sed 's/_.*//')
    END_VERSIONS
    """
}
