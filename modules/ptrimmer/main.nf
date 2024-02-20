process PTRIMMER {

    publishDir "${params.outdir}/${meta.sample_id}/PTRIMMER", mode: 'copy'

    label 'short_serial'

    tag "${meta.sample_id}|${meta.library_id}|${meta.readgroup_id}"

    conda 'bioconda::ptrimmer=1.3.3.'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ptrimmer:1.3.3--h50ea8bc_5' :
        'quay.io/biocontainers/ptrimmer:1.3.3--h50ea8bc_5' }"


    input:
    tuple val(meta),path(r1),path(r2)
    path(amplicon_txt)

    output:
    tuple val(meta),path(r1_trimmed),path(r2_trimmed), emit: reads
    path('versions.yml'), emit: versions

    script:
    r1_trimmed = r1.getBaseName() + "_ptrimmed.fastq"
    r2_trimmed = r2.getBaseName() + "_ptrimmed.fastq"

    """
    ptrimmer -t pair -a $amplicon_txt -f $r1 -d $r1_trimmed -r $r2 -e $r2_trimmed 
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        Ptrimmer: \$(ptrimmer --help 2>&1 | grep Version | sed -e "s/Version: //g")
    END_VERSIONS

    """

}