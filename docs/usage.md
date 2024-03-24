# Usage information

This is not a full release. Please note that some things may not work as intended yet. 

# Running the pipeline

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```
nextflow run marchoeppner/gmo-check -profile standard,singularity --input samples.csv --genome tomato --reference_base /path/to/references --run_name pipeline-test
```
where `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references. 

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Other options to provision software are:

`-profile standard,singularity`

`-profile standard,docker` 

`-profile standard,podman` 

`-profile standard,conda` THIS ISN'T FULLY SUPPORTED YET! To Do

b) with a site-specific config file

```
nextflow run marchoeppner/gmo-check -profile lsh --input samples.csv --genome tomato --run_name pipeline-text
```

In this example, both `--reference_base` and the choice of software provisioning are already set in your local configuration and don't have to provided as command line argument. 

# Options

## `--input samplesheet.csv` [default = null]

This pipeline expects a CSV-formatted sample sheet to properly pull various meta data through the processes. The required format looks as follows:

```
sample_id,library_id,readgroup_id,R1,R2
S100,S100,AACYTCLM5.1.S100,/home/marc/projects/gaba/data/S100_R1.fastq.gz,/home/marc/projects/gaba/data/S100_R2.fastq.gz
```

If you are unsure about the readgroup ID, just make sure that it is unique for the combination of library, flowcell and lane. Typically it would be constructed from these components - and the easiest way to get it is from the FastQ file itself (header of read 1, for example).

## `--genome tomato` [default = tomato]

The name of the pre-configured genome to analyze against. This parameter controls not only the mapping reference (if you use a mapping-based analysis), but also which internally pre-configured configuration files are used. Currently, only one genome can be analyzed per pipeline run. 

Available options:

- tomato

## `--run_name Fubar` [default = null]

A mandatory name for this run, to be included with the result files. 

## `--email me@google.com` [ default = null]

An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured. 

## `--tools vsearch` [default = vsearch]

This pipeline supports two completely independent tool chains:

- `vsearch` using a simple "metagenomics-like" amplicon processing workflow to produce dereplicated sequences from the short reads to then search for pre-defined patterns against a BLAST database (built-in)

- `bwa2` uses a classic variant calling approach, with parameters similar to what one would find in cancer analysis to detect low-frequency SNPs in mixed samples. 

You can specify either one, or both: `--tools 'vsearch,bwa2'` 

Which tool chain is the best choice? Well, technically both options give near-identical results. So in this case `vsearch` would be the better option since it runs significantly faster. However, this pipeline is designed to (theoretically) handle many more types of genetic variants, not all of which are necessarily detectable without a proper variant calling. This is why the `bwa2` option exists - future proofing. 

## `--reference_base` [default = null ]

The location of where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one. 

## `--outdir results` [default = results]

The location where the results are stored. Usually this will be `results`in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s). 

## `--freebayes_min_alternate_count 50` [ default = 50]
The minimum number of reads to support a given SNP. Since we are working with amplicon data, this value can be fairly high. 

## `--freebayes_min_alternate_frac 0.01` [ default = 0.01]
The minimum percentage of reads supporting a SNP at a given site for the SNP to be considered. The default of 1% is chosen to be able to detect low levels of contribution but may need some tweaking depending on your exact sequencing setup and coverage. 