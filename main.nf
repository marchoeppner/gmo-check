#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

/**
===============================
GMO-check Pipeline
===============================

This Pipeline performs detection of genetic events in food and seed material(s) (GMO analysis).

### Homepage / git
git@github.com:marchoeppner/gmo-check.git

**/

// Pipeline version
params.version = workflow.manifest.version

include { GMO }                 from './workflows/gmo'
include { BUILD_REFERENCES }    from './workflows/build_references'
include { PIPELINE_COMPLETION } from './subworkflows/pipeline_completion'
include { paramsSummaryLog }    from 'plugin/nf-schema'

workflow {

    // Print summary of supplied parameters
    log.info paramsSummaryLog(workflow)

    WorkflowMain.initialise(workflow, params, log)
    WorkflowPipeline.initialise(params, log)

    if (!workflow.containerEngine) {
        log.warn "NEVER USE CONDA FOR PRODUCTION PURPOSES!"
    }

    if (params.build_references) {
        BUILD_REFERENCES()
    } else {
        GMO()
    }

    PIPELINE_COMPLETION()
}