#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import vcf
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--vcf", help="A VCF file")
parser.add_argument("--json", help="A rule set in JSON format")
parser.add_argument("--coverage", help="The BAM coverage")
parser.add_argument("--sample", help="The sample name")
parser.add_argument("--output")
args = parser.parse_args()

def main(sample, vcf_file, ref_data, coverage_file, output):
    
    coverages = {}

    # Read BAM coverage and store in dict
    cov_lines = [line.strip() for line in open(coverage_file, 'r')]
    for line in cov_lines:
        seq,seq_from,seq_to,name,cov = [ str(i) for i in line.split("\t") ]
        coverages[name] = float(cov)

    result = { "sample": sample, "matches": [] }

    # Parse the JSON file
    with open(ref_data) as f:
        refs = json.load(f)

    rules = refs["rules"]["bwa-freebayes"]["payload"]

    # Read the VCF file
    records = vcf.Reader(open(vcf_file), "r")

    for rule in rules:

        rule_name = rule["name"]
        rule_string = rule["matcher"]

        this_cov = coverages[rule_name] if rule_name in coverages else "NA"

        this_match = { "toolchain": "bwa2" , "rule": rule_name, "bam_cov": this_cov }

        has_matched = False

        for record in records:

            allele_string = f"{record.CHROM}\t{record.POS}\t.\t{record.REF}\t{record.ALT[0]}"
            
            this_sample = record.samples[0] # pragmatic, since this vcf file should only contain a single sample

            # Our rule matches this allele string
            if rule_string == allele_string:

                has_matched = True

                this_match["report"] = rule["positive_report"]

                genotype = this_sample["GT"]

                # ALT found, but data not sufficient to actually call variant
                if genotype == "0/0":
                    this_match["comment"] = "Variantenfrequenz unter Call-Schwelle!"
                
                rcov,acov = [ int(i) for i in this_sample["AD"] ]
                cov_sum = acov + rcov

                # Freebayes counts invididual reads even if they overlap
                # To get the real coverage, we take the mosdepth coverage
                # and derive coverages via the AD fractions at this locus
                if this_cov != "NA":
                    rfrac = float(rcov)/float(cov_sum)
                    afrac = float(acov)/float(cov_sum)
                    rcov = round((rfrac * this_cov),0)
                    acov = round((afrac * this_cov),0)
                    cov_sum = this_cov

                perc = (float(acov) / float(cov_sum)) * 100.0

                this_match["perc_gmo"] = round(perc, 2)
                this_match["ref_cov"] = rcov
                this_match["alt_cov"] = acov

                result["matches"].append(this_match)

        # Nothing has matched at all, so we return a placeholder
        if not has_matched:
            this_match["report"] = rule["negative_report"]
            this_match["ref_cov"] = "NA"
            this_match["alt_cov"] = "NA"
            this_match["perc_gmo"] = 0.0
            result["matches"].append(this_match)

    with open(output, "w") as fo:
        json.dump(result, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.sample, args.vcf, args.json, args.coverage, args.output)
