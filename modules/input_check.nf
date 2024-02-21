//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep: ',')
        .map { fastq_channel(it) }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
}

def fastq_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.sample_id         = row.sample_id
    meta.readgroup_id      = row.readgroup_id
    meta.library_id        = row.library_id

    // add path(s) of the fastq file(s) to the meta map
    def fastqMeta = []
    if (!file(row.R1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.R1}"
    }
    if (!file(row.R2).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.R2}"
    }
    fastqMeta = [ meta, file(row.R1), file(row.R2) ]

    return fastqMeta
}
