//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//

class WorkflowPipeline {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        if (!params.run_name) {
            log.info 'Must provide a run_name (--run_name)'
            System.exit(1)
        }
        if (params.tools.contains('bwa2') && !params.reference_base) {
            log.info 'Cannot run the alignment workflow without genome references (--reference_base). Please check the documentation!'
            System.exit(1)
        }
        if ( !params.input && !params.build_references) {
            log.info "This pipeline requires a sample sheet as input (--input)"
            System.exit(1)
        }
    }
}
