
include { INPUT_CHECK }                 from '../modules/input_check'
include { FASTP }                       from '../modules/fastp'
include { SOFTWARE_VERSIONS }           from '../modules/software_versions'
include { MULTIQC }                     from './../modules/multiqc'
include { BLAST_MAKEBLASTDB }           from "./../blast/makeblastdb"
include { VSEARCH_WORKFLOW }            from "./../subworkflows/vsearch"
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

ch_db_file = Channel.fromPath("${baseDir}/assets/blastdb.fasta", checkIfExists: true)

samplesheet = Channel.fromPath(params.input, checkIfExists: true).collect()

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

tools = params.tools ? params.tools.split(',').collect{it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '')} : []

workflow GMO {
    take:
    samplesheet

    main:

    // read the sample sheet and turn into channel with meta hash
    INPUT_CHECK(samplesheet)

    // trim reads using fastP
    FASTP(
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    // Merging and deduplication of amplicons combined with Diamond
    if ('vsearch' in tools) {

        MAKEBLASTDB(
            ch_db_file
        )

        VSEARCH_WORKFLOW(
            FASTP.out.reads,
            MAKEBLASTDB.out.db.collect()
        )

        ch_versions = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
    }

    SOFTWARE_VERSIONS(
        ch_versions.collect()
    )

    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect()
    )

    emit:
    qc = MULTIQC.out.html
}
