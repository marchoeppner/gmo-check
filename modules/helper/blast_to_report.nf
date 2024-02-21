process BLAST_TO_REPORT {

    tag "${meta.sample_id}"

    publishDir "${params.outdir}/Reports", mode: 'copy'

    input:
    tuple val(meta),path(blast)
    path(rules)

    output:
    tuple val(meta),path(report), emit: json

    script:
    report = blast.getBaseName() + ".report.json"

    """
    analyze_blast.rb -b $blast -j $rules -s ${meta.sample_id} > $report
    """

}