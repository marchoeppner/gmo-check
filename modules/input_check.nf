//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep:',')
        .map { dh ->
            fastq_channel_from_hash(dh)
        }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def fastq_channel_from_hash(LinkedHashMap row) {
    meta = [:]
    meta.sample_id    = row.patient_id
    meta.library_id   = row.library_id
    meta.readgroup_id = row.rgID

    array = []
    if (!file(row.R1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.R1}"
    }
    if (!file(row.R2).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.R2}"
    }
    array = [ meta, [ file(row.R1), file(row.R2) ] ]
    return array
}
