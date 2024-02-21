process BLAST_BLASTN {
    publishDir "${params.outdir}/Processing/BlastN", mode: 'copy'

    label 'short_parallel'

    conda 'bioconda::blast=2.15'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    tuple val(meta), path(fasta)
    path(db)

    output:
    tuple val(meta), path(blastout), emit: results
    path("versions.yml"), emit: versions

    script:
    blastout = meta.sample_id + '.blast.json'

    """
    DB=`find -L ./ -name "*.nal" | sed 's/\\.nal\$//'`
    if [ -z "\$DB" ]; then
        DB=`find -L ./ -name "*.nin" | sed 's/\\.nin\$//'`
    fi
    echo Using \$DB

    blastn -num_threads ${task.cpus} \
        -db \$DB \
        -query $fasta \
        -outfmt 15 \
        -out $blastout \
        -evalue 0.0001

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS

    """
}
