//
// This file holds several functions specific to the workflow/esga.nf in the nf-core/esga pipeline
//
class WorkflowMain {

    //
    // Check and validate parameters
    //
    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {
        log.info header(workflow)

        // Print help to screen if required
        if (params.help) {
            log.info help(workflow)
            System.exit(0)
        }
    }

    public static String header(workflow) {
        def headr = ''
        def infoLine = "${workflow.manifest.description} | version ${workflow.manifest.version}"
        headr = """
    ===============================================================================
    ${infoLine}
    ===============================================================================
    """
        return headr
    }

    public static String help(workflow) {
        def command = "nextflow run ${workflow.manifest.name} --input some_file.csv --email me@gmail.com"
        def helpString = ''
        // Help message
        helpString = """

            Usage: $command

            Required parameters:
            --input                        The primary pipeline input (typically a CSV file)
            --email                        Email address to send reports to (enclosed in '')
            --tools                        A comma-separated list of tool chains to run (vsearch, bwa2)
            Optional parameters:
            --genome                       Use this reference genome when requesting 'bwa2' tool chain
            --run_name                     A descriptive name for this pipeline run
            Output:
            --outdir                       Local directory to which all output is written (default: results)
        """
        return helpString
    }

}
