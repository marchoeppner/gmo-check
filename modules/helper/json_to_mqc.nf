process JSON_TO_MQC {

    tag 'All'
    
    publishDir "${params.outdir}/Reports", mode: 'copy'

    input:
    path(jsons)

    output:
    path("*_mqc.tsv"), emit: mqc

    script:

    """
    reports_to_table.rb 
    """
}
