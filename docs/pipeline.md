# Pipeline structure

![](images/pipeline_dag.png)

This pipeline performs nucleotide-level analysis of sequencing data to identify diagnostic variants against a set of pre-configured references. 

Two main approaches are available:

## Variant calling (`--tools bwa`)

Variant calling refers to a process in which quality-controlled reads are mapped against a reference sequence or genome. These mappings are then checked for any base-level differences across all the reads to identify putative genetic variations above pre-configured frequency and quality thresholds. The presence of a non-wild-type variant can then be expressed as a SNP or (INDEL) at a specific frequency. 

## OTU assembly (`--tools vsearch`)

OTU assembly is a process in which all the reads of a sample are clustered based on sequence identity. Any genetic variants should seed their own cluster (OTU), as long as the clustering threshold is set appropriately. The product are (usally) two OTUs per sample - one with the wild type sequence, and on with the variant sequence. The presence of a specific variant sequence is then checked against reference sequences using a BLAST search.
