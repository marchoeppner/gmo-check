/*
Modules to include
*/
include { INPUT_CHECK }                 from './../modules/input_check'
include { MULTIQC }                     from './../modules/multiqc'
include { BLAST_MAKEBLASTDB }           from './../modules/blast/makeblastdb'
include { JSON_TO_XLSX }                from './../modules/helper/json_to_xlsx'
include { JSON_TO_MQC }                 from './../modules/helper/json_to_mqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

/*
Subworkflows to include
*/
include { VSEARCH_WORKFLOW }            from './../subworkflows/vsearch'
include { DADA2_WORKFLOW }              from './../subworkflows/dada2'
include { BWAMEM2_WORKFLOW }            from './../subworkflows/bwamem2'
include { TRIMMING }                    from './../subworkflows/trimming'

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
    bwa_index       = Channel.fromPath(file(params.references.genomes[params.genome].fasta).parent).collect()      // a directory with the BWA2 index files
    references      = [ fasta, fai, dict ]                                                               // The fasta reference with fai and dict (mostly Freebayes)
    ch_amplicon_txt = Channel.fromPath(params.references.genomes[params.genome].amplicon_txt).collect()  // The ptrimmer primer manifest
    ch_rules        = Channel.fromPath(params.references.genomes[params.genome].rules).collect()         // rules to define what we consider a hit

    samplesheet     = params.input ? Channel.fromPath(params.input) : Channel.value([])                  // the samplesheet with name and location of the sample(s)

    ch_multiqc_config = params.multiqc_config ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect()    : []
    ch_multiqc_logo   = params.multiqc_logo   ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect()      : []

    ch_versions     = Channel.from([])
    multiqc_files   = Channel.from([])
    ch_reports      = Channel.from([])

    pipeline_settings = Channel.fromPath(dumpParametersToJSON(params.outdir)).collect()

    // Capture list of requested tool chains
    tools = params.tools ? params.tools.split(',').collect { it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '') } : []

    // read the sample sheet and turn into channel with meta hash
    INPUT_CHECK(samplesheet)

    // Trim reads
    TRIMMING(
        INPUT_CHECK.out.reads,
        ch_amplicon_txt
    )
    ch_versions = ch_versions.mix(TRIMMING.out.versions)
    multiqc_files = multiqc_files.mix(TRIMMING.out.qc)

    /*
    Perform alignment and variant calling
    using BWA-MEM2 and Freebayes
    */
    if ('bwa2' in tools) {
        BWAMEM2_WORKFLOW(
            TRIMMING.out.trimmed,
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
            TRIMMING.out.trimmed,
            BLAST_MAKEBLASTDB.out.db.collect(),
            ch_rules
        )
        ch_versions = ch_versions.mix(VSEARCH_WORKFLOW.out.versions)
        ch_reports  = ch_reports.mix(VSEARCH_WORKFLOW.out.reports)
    }
    /*
    Amplicon clustering and pattern matching
    against a BLAST database with Dada2
    */
    if ('dada2' in tools) {
        BLAST_MAKEBLASTDB(
            ch_db_file
        )
        ch_versions = ch_versions.mix(BLAST_MAKEBLASTDB.out.versions)

        DADA2_WORKFLOW(
            TRIMMING.out.trimmed,
            BLAST_MAKEBLASTDB.out.db.collect(),
            ch_rules
        )
        ch_versions = ch_versions.mix(DADA2_WORKFLOW.out.versions)
        ch_reports  = ch_reports.mix(DADA2_WORKFLOW.out.reports)
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

// turn the summaryMap to a JSON file
def dumpParametersToJSON(outdir) {
    def timestamp = new java.util.Date().format('yyyy-MM-dd_HH-mm-ss')
    def filename  = "params_${timestamp}.json"
    def temp_pf   = new File(workflow.launchDir.toString(), ".${filename}")
    def jsonStr   = groovy.json.JsonOutput.toJson(params)
    temp_pf.text  = groovy.json.JsonOutput.prettyPrint(jsonStr)

    nextflow.extension.FilesEx.copyTo(temp_pf.toPath(), "${outdir}/pipeline_info/params_${timestamp}.json")
    temp_pf.delete()
    return file("${outdir}/pipeline_info/params_${timestamp}.json")
}