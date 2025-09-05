/*
Modules to include
*/
include { INPUT_CHECK }                 from './../modules/input_check'
include { FASTP }                       from './../modules/fastp'
include { MULTIQC }                     from './../modules/multiqc'
include { BLAST_MAKEBLASTDB }           from './../modules/blast/makeblastdb'
include { BIOBLOOMTOOLS_CATEGORIZER }   from './../modules/biobloomtools/categorizer'
include { JSON_TO_XLSX }                from './../modules/helper/json_to_xlsx'
include { JSON_TO_MQC }                 from './../modules/helper/json_to_mqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

/*
Subworkflows to include
*/
include { VSEARCH_WORKFLOW }            from './../subworkflows/vsearch'
include { BWAMEM2_WORKFLOW }            from './../subworkflows/bwamem2'

// workflow starts here
workflow GMO {

    main:

    /*
    Check if there references are installed
    */
    refDir = file(params.reference_base + "/gmo-check/${params.reference_version}")
    if (!refDir.exists()) {
        log.info 'The required reference directory was not found on your system, exiting!'
        System.exit(1)
    }
    /*
    Set default channels
    */
    ch_db_file      = Channel.fromPath("${baseDir}/assets/blastdb.fasta.gz", checkIfExists: true)        // The built-in blast database
    fasta           = params.references.genomes[params.genome].fasta                                     // The reference genome to be used
    fai             = params.references.genomes[params.genome].fai                                       // The fasta index of the reference genome
    dict            = params.references.genomes[params.genome].dict                                      // The dictionary of the reference genome
    bwa_index       = Channel.fromPath(file(params.references.genomes[params.genome].fasta).parent)      // a directory with the BWA2 index files
    references      = [ fasta, fai, dict ]                                                               // The fasta reference with fai and dict (mostly Freebayes)
    ch_amplicon_txt = Channel.fromPath(params.references.genomes[params.genome].amplicon_txt).collect()  // The ptrimmer primer manifest
    ch_rules        = Channel.fromPath(params.references.genomes[params.genome].rules).collect()         // rules to define what we consider a hit

    samplesheet     = params.input ? Channel.fromPath(params.input) : Channel.value([])                  // the samplesheet with name and location of the sample(s)

    ch_multiqc_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect()    : []
    ch_multiqc_logo   = params.multiqc_logo   ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect()      : []

    ch_versions     = Channel.from([])
    multiqc_files   = Channel.from([])
    ch_reports      = Channel.from([])

    // Capture list of requested tool chains
    tools = params.tools ? params.tools.split(',').collect { it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '') } : []

    // read the sample sheet and turn into channel with meta hash
    INPUT_CHECK(samplesheet)

    // Remove PhiX using a bloom filter
    BIOBLOOMTOOLS_CATEGORIZER(
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(BIOBLOOMTOOLS_CATEGORIZER.out.versions)
    multiqc_files = multiqc_files.mix(BIOBLOOMTOOLS_CATEGORIZER.out.results)

    // trim reads using fastP in automatic mode and with overlap correction
    FASTP(
        BIOBLOOMTOOLS_CATEGORIZER.out.reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    /*
    Perform alignment and variant calling
    using BWA-MEM2 and Freebayes
    */
    if ('bwa2' in tools) {
        BWAMEM2_WORKFLOW(
            FASTP.out.reads,
            references,
            bwa_index,
            ch_rules
        )
        multiqc_files   = multiqc_files.mix(BWAMEM2_WORKFLOW.out.qc)
        ch_versions     = ch_versions.mix(BWAMEM2_WORKFLOW.out.versions)
        ch_reports      = ch_reports.mix(BWAMEM2_WORKFLOW.out.reports)
    }
    
    /*
    Amplicon clustering and pattern-matching
    against a BLAST database
    */
    if ('vsearch' in tools) {
        BLAST_MAKEBLASTDB(
            ch_db_file
        )
        ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions)

        VSEARCH_WORKFLOW(
            FASTP.out.reads,
            BLAST_MAKEBLASTDB.out.db.collect(),
            ch_amplicon_txt,
            ch_rules
        )
        ch_versions = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
        ch_reports  = ch_reports.mix(VSEARCH_WORKFLOW.out.reports)
    }

    // Parse all reports and make an XLS file
    JSON_TO_XLSX(
        ch_reports.map { meta, j -> j }.collect()
    )

    // Parse all reports and make MultiQC compatible table
    JSON_TO_MQC(
        ch_reports.map { meta, j -> j }.collect()
    )
    multiqc_files = multiqc_files.mix(JSON_TO_MQC.out.mqc)

    // Dump all the software versions to YAML
    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )
    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.html
}
