
include { INPUT_CHECK }                 from './../modules/input_check'
include { FASTP }                       from './../modules/fastp'
include { MULTIQC }                     from './../modules/multiqc'
include { BLAST_MAKEBLASTDB }           from './../modules/blast/makeblastdb'
include { VSEARCH_WORKFLOW }            from './../subworkflows/vsearch'
include { BWAMEM2_WORKFLOW }            from './../subworkflows/bwamem2'
include { BIOBLOOMTOOLS_CATEGORIZER }   from './../modules/biobloomtools/categorizer'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from './../modules/custom/dumpsoftwareversions'

ch_db_file      = Channel.fromPath("${baseDir}/assets/blastdb.fasta.gz", checkIfExists: true)        // The built-in blast database
fasta           = params.references.genomes[params.genome].fasta                                     // The reference genome to be used
fai             = params.references.genomes[params.genome].fai                                       // The fasta index of the reference genome    
dict            = params.references.genomes[params.genome].dict                                      // The dictionary of the reference genome
references      = [ fasta, fai, dict ]                                                                                          

ch_bed          = Channel.fromPath(params.references.genomes[params.genome].bed).collect()           // Bed file with primer locations
ch_targets      = Channel.fromPath(params.references.genomes[params.genome].target_bed).collect()    // Bed file with calling regions
ch_amplicon_txt = Channel.fromPath(params.references.genomes[params.genome].amplicon_txt).collect()  // The ptrimmer primer manifest
ch_rules        = Channel.fromPath(params.references.genomes[params.genome].rules).collect()         // rules to define what we consider a hit

samplesheet     = params.input ? Channel.fromPath(params.input) : Channel.value([])                  // the samplesheet with name and location of the sample(s)

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

// Capture list of requested tool chains
tools = params.tools ? params.tools.split(',').collect { it.trim().toLowerCase().replaceAll('-', '').replaceAll('_', '') } : []

// workflow starts here
workflow GMO {
    main:

    // read the sample sheet and turn into channel with meta hash
    INPUT_CHECK(samplesheet)

    // Remove PhiX using a bloom filter
    BIOBLOOMTOOLS_CATEGORIZER(
        INPUT_CHECK.out.reads
    )
    ch_versions = ch_versions.mix(BIOBLOOMTOOLS_CATEGORIZER.out.versions)
    multiqc_files = multiqc_files.mix(BIOBLOOMTOOLS_CATEGORIZER.out.results)

    // trim reads using fastP in automatic mode
    FASTP(
        BIOBLOOMTOOLS_CATEGORIZER.out.reads
    )
    ch_versions = ch_versions.mix(FASTP.out.versions)
    multiqc_files = multiqc_files.mix(FASTP.out.json)

    // Performing proper variant calling with BWA2 and Freebayes
    if ('bwa2' in tools) {
        BWAMEM2_WORKFLOW(
            FASTP.out.reads,
            references,
            ch_bed,
            ch_rules,
            ch_targets
        )
        multiqc_files = multiqc_files.mix(BWAMEM2_WORKFLOW.out.qc)
        ch_versions = ch_versions.mix(BWAMEM2_WORKFLOW.out.versions)
    }

    // Merging and deduplication of amplicons combined with BlastN
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
