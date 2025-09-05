process JSON_TO_XLSX {
    tag 'All'

    publishDir "${params.outdir}/Reports", mode: 'copy'

    input:
    path(jsons)

    output:
    path(excel), emit: xlsx

    script:
    excel = params.run_name + '.xlsx'

    """
    reports_to_xls_v2.rb --outfile $excel
    """
}
