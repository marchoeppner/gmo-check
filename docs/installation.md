# Installation

This is not a full release. Please note that some things may not work as intended yet. 
Specifically: While most processes will use containers or conda environments as requested, the final reporting steps currently require locally:

- ruby v >= 3.0
- gems: json, rubyXL

This will be corrected towards the full 1.0 release, at which point the pipeline will be fully platform-independent and self-contained. 

## Installing the references

This pipeline requires locally stored genomes in fasta format. To build these, do:

```
nextflow run marchoeppner/gmo-check -profile standard,singularity --build_references --run_name build_refs --outdir /path/to/references
```

where `/path/to/references` could be something like `/data/pipelines/references` or whatever is most appropriate on your system. 

If you do not have singularity on your system, you can also specify docker, podman or conda for software provisioning - see the [usage information](usage.md).

The path specified with `--outdir` can then be given to the pipeline during normal execution as `--reference_base`. Please note that the build process will create a pipeline-specific subfolder (`gmo-check`) that must not be given as part of the `--outdir` argument. Gmo-check is part of a collection of pipelines that use a shared reference directory and it will choose the appropriate subfolder by itself. 

## Site-specific config file

If you run on anything other than a local system, this pipeline requires a site-specific configuration file to be able to talk to your cluster or compute infrastructure. Nextflow supports a wide range of such infrastructures, including Slurm, LSF and SGE - but also Kubernetes and AWS. For more information, see [here](https://www.nextflow.io/docs/latest/executor.html).

Site-specific config-files for our pipeline ecosystem are stored centrally on [github](https://github.com/marchoeppner/configs). Please talk to us if you want to add your system