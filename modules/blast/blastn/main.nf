process BLAST_BLASTN {

    publishDir "${params.outdir}/BlastN", mode: 'copy'

    label 'short_parallel'

    conda 'bioconda::blast=2.15'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/blast:2.15.0--pl5321h6f7f691_1' :
        'quay.io/biocontainers/blast:2.15.0--pl5321h6f7f691_1' }"

    input:
    tuple val(meta),path(fasta)
    tuple path(db)

    output:
    tuple val(meta),path(result), emit: blastout

    script:
    blastout = meta.sample_id + ".blast.txt"

    """
    DB=`find -L ./ -name "*.nal" | sed 's/\\.nal\$//'`
    if [ -z "\$DB" ]; then
        DB=`find -L ./ -name "*.nin" | sed 's/\\.nin\$//'`
    fi
    echo Using \$DB

    blastn -num_threads ${task.cpus} \
        -db \$DB \
        -outfmt 6 \
        -query $fasta \
        -out $blastout

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        blast: \$(blastn -version 2>&1 | sed 's/^.*blastn: //; s/ .*\$//')
    END_VERSIONS

    """
}