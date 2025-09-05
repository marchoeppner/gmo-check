process BWAMEM2_MEM {
    tag "${meta.sample_id}"

    conda "${moduleDir}/environment.yml"
    container 'quay.io/biocontainers/mulled-v2-e5d375990341c5aef3c9aff74f96f66f65375ef6:2cdf6bf1e92acbeb9b2834b1c58754167173a410-0'

    label 'short_parallel'

    input:
    tuple val(meta), path(reads)
    path(bwa_index)
    tuple path(fasta),path(fai),path(dict)

    output:
    tuple val(meta), path(bam), emit: bam
    path("versions.yml"), emit: versions

    script:
    bam = "${meta.sample_id}_${meta.library_id}_${meta.readgroup_id}_bwa2-aligned.fm.bam"

    """
    INDEX=`find -L ./ -name "*.amb" | sed 's/\\.amb\$//'`

    bwa-mem2 mem -H ${dict} -M \
    -R "@RG\\tID:${meta.readgroup_id}\\tPL:ILLUMINA\\tSM:${meta.sample_id}\\tLB:${meta.library_id}\\tDS:${fasta}" \
    -t ${task.cpus} \
    \$INDEX \
    $reads \
    | samtools fixmate -@ ${task.cpus} -m - - \
    | samtools sort -@ ${task.cpus} -m 2G -O bam -o $bam -

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bwamem2: \$(echo \$(bwa-mem2 version 2>&1) | sed 's/.* //')
        samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    END_VERSIONS
    """
}
