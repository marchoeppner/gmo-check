
include { INPUT_CHECK }                 from './../modules/input_check'
include { FASTP }                       from './../modules/fastp'
include { MULTIQC }                     from './../modules/multiqc'
include { BLAST_MAKEBLASTDB }           from './../modules/blast/makeblastdb'
include { VSEARCH_WORKFLOW }            from './../subworkflows/vsearch'
include { BWAMEM2_WORKFLOW }            from './../subworkflows/bwamem2'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

ch_db_file      = Channel.fromPath(params.references['blastdb'], checkIfExists: true)
fasta           = params.references.genomes['tomato'].fasta
dict            = params.references.genomes['tomato'].dict
references      = [ fasta, dict ]

ch_primers      = Channel.fromPath(params.references.genomes['tomato'].primers).collect()
ch_bed          = Channel.fromPath(params.references.genomes['tomato'].bed).collect()

samplesheet     = Channel.fromPath(params.input)

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

// Capture list of requested tool chains
tools = params.tools ? params.tools.split(',').collect { it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '') } : []

// workflow starts here
workflow GMO {
    main:

    // read the sample sheet and turn into channel with meta hash
    INPUT_CHECK(samplesheet)

    // trim reads using fastP
    FASTP(
        INPUT_CHECK.out.reads,
        ch_primers
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    // Performing a proper variant calling
    if ('bwa2' in tools) {
        BWAMEM2_WORKFLOW(
            FASTP.out.reads,
            fasta,
            dict,
            ch_bed
        )
        multiqc_files = multiqc_files.mix(BWAMEM2_WORKFLOW.out.qc)
        ch_versions = BWAMEM2_WORKFLOW.out.versions
    }

    // Merging and deduplication of amplicons combined with BlastN
    if ('vsearch' in tools) {
        BLAST_MAKEBLASTDB(
            ch_db_file
        )
        ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions)

        VSEARCH_WORKFLOW(
            FASTP.out.reads,
            BLAST_MAKEBLASTDB.out.db.collect()
        )
        ch_versions = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
    }

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
