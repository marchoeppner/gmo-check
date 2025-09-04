# Usage information

This is not a full release. Please note that some things may not work as intended yet. 

[Running the pipeline](#running-the-pipeline)

[Options](#options)

[Resources](#resources)


## Running the pipeline

A basic execution of the pipeline looks as follows:

a) Without a site-specific config file

```bash
nextflow run marchoeppner/gmo-check -profile standard,singularity \\
--input samples.csv \\
--genome tomato \\
--reference_base /path/to/references \\
--run_name pipeline-test
```
where `path_to_references` corresponds to the location in which you have [installed](installation.md) the pipeline references. 

In this example, the pipeline will assume it runs on a single computer with the singularity container engine available. Other options to provision software are:

`-profile standard,docker` 

`-profile standard,podman` 

`-profile standard,conda` THIS ISN'T FULLY SUPPORTED YET! To Do

b) with a site-specific config file

```
nextflow run marchoeppner/gmo-check -profile lsh --input samples.csv --genome tomato --run_name pipeline-text
```

In this example, both `--reference_base` and the choice of software provisioning are already set in your site-specific configuration and don't have to provided as command line argument. 

## Options

### `--input samples.csv` [default = null]

This pipeline expects a CSV-formatted sample sheet to properly pull various meta data through the processes. The required format looks as follows:

```CSV
sample,library_id,readgroup_id,R1,R2
S100,S100,AACYTCLM5.1.S100,/home/marc/projects/gaba/data/S100_R1.fastq.gz,/home/marc/projects/gaba/data/S100_R2.fastq.gz
```

| Column | Description |
| ------ | ----------- |
| sample | A unique identifier for this sample |
| library_id | The name/id of a specific library (samples may have more than one library!) |
| readgroup_id | A unique identifier for the combination of library, land and flow cell |
| R1 | The full path to the forward reads |
| R2 | The full path to the reverse reads |

The columns `sample_id` and `library_id` should be self-explanatory. 

<details markdown=1>
<summary>About read groups</summary>
Read groups are used in variant calling to distinguish data from different lanes or sequencing runs. This is important as lanes and runs may exhibit different characteristics. For the present pipeline, the effects are perhaps neglibible - partly because it is unlikely that data from lanes or runs need to be merged - but it is good practice in variant calling, so we adopt it.

If you are uncertain about `readgroup_id`, just make sure that it is unique for the combination of library, flowcell and lane. Typically it would be constructed from these components - and the easiest way to get it is from the FastQ file itself (header of read 1, for example).

```
@VL00316:70:AACYTCLM5:1:1101:18686:1038 1:N:0:AAGCGGTGAA+AACCTAGACG
```
For a hypothetical library called "LIB100", this  can be turned into the readgroup id: `AACYTCLM5.1.LIB100` - where `AACYTCLM5` is the ID of the flowcell, `1` is the lane on that flow cell and `LIB100` is the identifier of the library. 

</details>

### `--genome tomato` [default = tomato]

The name of the pre-configured genome to analyze against. This parameter controls not only the mapping reference (if you use a mapping-based analysis), but also which internally pre-configured configuration files are used. Currently, only one genome can be analyzed per pipeline run. 

Available options:

- tomato

### `--run_name Fubar` [default = null]

A mandatory name for this run, to be included with the result files. 

### `--email me@google.com` [ default = null]

An email address to which the MultiQC report is send after pipeline completion. This requires for the executing system to have [sendmail](https://rimuhosting.com/support/settingupemail.jsp?mta=sendmail) configured. 

### `--tools vsearch` [default = vsearch]

This pipeline supports two completely independent tool chains:

- `vsearch` using a simple "metagenomics-like" amplicon processing workflow to produce dereplicated sequences from the short reads to then search for pre-defined patterns against a BLAST database (built-in)

- `bwa2` uses a classic variant calling approach, with parameters similar to what one would find in cancer analysis to detect low-frequency SNPs in mixed samples. 

You can specify either one, or both: `--tools 'vsearch,bwa2'` 

Which tool chain is the best choice? Well, technically both options give near-identical results. So in this case `vsearch` would be the better option since it runs significantly faster. However, this pipeline is designed to (theoretically) handle many more types of genetic variants, not all of which are necessarily detectable without a proper variant calling. This is why the `bwa2` option exists - future proofing. 

### `--reference_base` [default = null ]

The location of where the pipeline references are installed on your system. This will typically be pre-set in your site-specific config file and is only needed when you run without one. 

### `--outdir results` [default = results]

The location where the results are stored. Usually this will be `results`in the location from where you run the nextflow process. However, this option also accepts any other path in your file system(s). 

### `--freebayes_min_alternate_count 50` [ default = 50]
The minimum number of reads to support a given SNP. Since we are working with amplicon data, this value can be fairly high. 

### `--freebayes_min_alternate_frac 0.01` [ default = 0.01]
The minimum percentage of reads supporting a SNP at a given site for the SNP to be considered. The default of 1% is chosen to be able to detect low levels of contribution but may need some tweaking depending on your exact sequencing setup and coverage. 

## Resources

The following options can be set to control resource usage outside of a site-specific [config](https://github.com/marchoeppner/nf-configs) file.

### `--max_cpus` [ default = 16]

The maximum number of cpus a single job can request. This is typically the maximum number of cores available on a compute node or your local (development) machine. 

### `--max_memory` [ default = 128.GB ]

The maximum amount of memory a single job can request. This is typically the maximum amount of RAM available on a compute node or your local (development) machine, minus a few percent to prevent the machine from running out of memory while running basic background tasks.

### `--max_time`[ default = 240.h ]

The maximum allowed run/wall time a single job can request. This is mostly relevant for environments where run time is restricted, such as in a computing cluster with active resource manager or possibly some cloud environments.  