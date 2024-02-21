process JSON_TO_XLSX {
    tag 'All'

    publishDir "${params.outdir}/Reports", mode: 'copy'

    input:
    path(jsons)

    output:
    path(excel), emit: xlsx
    //path(delimited), emit: csv

    script:
    excel = params.run_name + '.xlsx'
    delimited = params.run_name + '.csv'

    """
    reports_to_xls.rb --outfile $excel
    """
}
