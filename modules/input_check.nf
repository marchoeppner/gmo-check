//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep:'\t')
        .map { row -> fastq_channel(row) }
        .set { reads }

    emit:
    reads // channel: [ val(meta), [ reads ] ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def fastq_channel(LinkedHashMap row) {

    def meta = [:]
    meta.sample_id      = row.sample
    meta.single_end     = false

    def array = []
    if (!row.sample) {
        exit 1, "ERROR: Missing mandatory column 'sample'\n"
    }
    if (!file(row.fq1).exists()) {
        exit 1, "ERROR: Please check input samplesheet -> Read 1 FastQ file does not exist!\n${row.fq1}"
    }

    if (row.readgroup_id) {
        meta.readgroup_id   = row.readgroup_id
    } else {
        log.warn "ERROR: No readgroup_id provided -using sample name!\n"
        meta.readgroup_id = row.sample
    }
    if (row.library_id) {
        meta.library_id = row.library_id
    } else {
        log.warn "ERROR: No library_id provided - using sample name!\n"
        meta.library_id = row.sample
    }

    if (row.fq2) {
        if (!file(row.fq2)) {
            exit 1, "ERROR: Please check input samplesheet -> Read 2 FastQ file does not exist!\n${row.fq2}"
        }
    } else {
        meta.single_end = true
    }
    if (meta.single_end) {
        array = [ meta, [ file(row.fq1)] ]
    } else {
        array = [ meta, [ file(row.fq1), file(row.fq2)] ]
    }
    
    return array
}

def get_metadata(String fastq) {

    def fq = file(fastq)

    // Does not currently work with gzipped files.
    fq.eachLine { str ->

        // @VL00316:70:AACYTCLM5:1:1101:18686:1038 1:N:0:AAGCGGTGAA+AACCTAGACG
        def (info, barcode) = str.split(" ")
        def elements = info.split(":")
        def instrument = elements[0]
        def flowcell = elements[2]
        def lane = elements[4]

        return [ "instrument": instrument, "lane": lane, "flowcell": flowcell, "barcode": barcode ]
    }
}