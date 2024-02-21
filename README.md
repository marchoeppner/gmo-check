# GMO-Check pipeline

This pipeline is being developed to detect GMO content from short-read (amplicon) data. Currently, only the detection of GABA mutations in tomato are supported. As this particular modification is characterized by a specific nucleotide insertion into the SIGAB3 gene, this is what the pipeline will currently try to check for. It does this by two independent approaches - classical variant calling on the one hand and the detection of the insertion in merged and dereplicated amplicon "ZOTUS" against a blast database containing the wild type gene sequence on the other. 

The variant calling workflow will first align quality- and adapter trimmed reads against the tomato reference genome (v3.0). It then masks out bases that start and overlap with the curated primer site locations using samtools ampliconclip. No deduplication will be performed to enable the accurate determination of GMO content in mixed samples. Finally, the read alignment is analyzed with Freebayes to determine the presence of any diagnostically relevant variants. 

For the amplicon-assembly approach, primer sequences are stripped from the reads using Ptrimmer. The stripped reads are then merged, filtered and reduced to unique "ZOTUS" with Vsearch. The resulting sequences are blasted against a  built-in database to check for evidence of the diagnostically relevant insertion. GMO content is determined by extracting the overall raw read count as annotated into the assembled and dereplicated reads for which a positive signal was determined with Blast versus the total number of raw reads represented in the reduced amplicon sequence set. 

Using a set of 126 samples, both approaches yielded very similar estimates for % GMO content in given sample (+/- 1%). 

## Documentation 

1. [What happens in this pipeline?](docs/pipeline.md)
2. [Installation and configuration](docs/installation.md)
3. [Running the pipeline](docs/usage.md)
4. [Output](docs/output.md)
5. [Software](docs/software.md)
5. [Troubleshooting](docs/troubleshooting.md)
6. [Developer guide](docs/developer.md)
