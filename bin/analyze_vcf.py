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


def is_match(ref, alt):

    ref_seq = ref["seq"]
    ref_pos = int(ref["pos"])
    ref_ref = ref["ref"]
    ref_alt = ref["alt"]

    ref_start = ref_pos
    ref_end = ref_start + len(ref_ref)

    alt_seq = alt["seq"]
    alt_pos = int(alt["pos"])
    alt_start = alt_pos
    alt_end = alt_pos + len(alt["ref"])
    alt_alt = alt["alt"]

    # Alt allele not defined for some reason, automatic fail
    if not alt_alt:
        return False

    # Not on the same chromosome, automatic fail
    if alt_seq != ref_seq:
        return False

    # Check if the rule overlaps this acual variant site
    if ref_start <= alt_end and ref_end >= alt_start:
        # yes, overlaps

        if alt_pos == ref_pos and ref_alt == alt_alt:
            return True  # perfect match
        else:
            # check if expected alt allele is perhaps contained within this actual alt_allele
            position = alt_alt.find(ref_alt)
            # Yes, allele of interest included in actual alt_allele
            if position >= 0:
                # Stats at the same position, so a match
                if position == 0 and alt_pos == ref_pos:
                    return True
                else:
                    # If the allele of interest is contained within this alt allele,
                    # we must check if the adjusted positions (alt_alle pos - internal position of allele of interest) match too
                    if (alt_pos + position + 1) == ref_pos:
                        return True

    return False


def main(sample, vcf_file, ref_data, coverage_file, output):

    coverages = {}

    # Read BAM coverage and store in dict
    cov_lines = [line.strip() for line in open(coverage_file, 'r')]
    for line in cov_lines:
        seq, seq_from, seq_to, name, cov = [str(i) for i in line.split("\t")]
        coverages[name] = float(cov)

    result = {"sample": sample, "matches": []}

    # Parse the JSON file
    with open(ref_data) as f:
        refs = json.load(f)

    # Rules that apply to variant data
    rules = refs["rules"]["bwa-freebayes"]["payload"]

    # Read the VCF file
    records = vcf.Reader(open(vcf_file), "r")

    # Read all the rules
    for rule in rules:

        rule_name = rule["name"]
        rule_string = rule["matcher"]
        rule_seq, rule_start, rule_phase, rule_ref, rule_alt = rule_string.split("\t")
        ref_allele = {"seq": rule_seq, "pos": rule_start, "ref": rule_ref, "alt": rule_alt}

        this_cov = coverages[rule_name] if rule_name in coverages else "NA"

        this_match = {"toolchain": "bwa2", "rule": rule_name, "bam_cov": this_cov}

        has_matched = False

        for record in records:

            alt_alleles = record.ALT  # one or more ALT alleles

            this_sample = record.samples[0]  # pragmatic, since this vcf file should only contain a single sample
            coverages = [int(i) for i in this_sample["AD"]]
            rcov = coverages[0]
            acov = 0
            cov_sum = sum(coverages)
            genotype_string = this_sample["GT"]
            # genotypes = genotype_string.split("/")

            # we may see more than one ALT allele when the call fraction is set very low!
            # must find the allele that matches our rule
            for idx, alt in enumerate(alt_alleles):

                # allele_string = f"{record.CHROM}\t{record.POS}\t.\t{record.REF}\t{alt}"
                alt_allele = {"seq": record.CHROM, "pos": record.POS, "ref": record.REF, "alt": str(alt)}

                this_index = idx + 1  # Some data (like coverages) refers to all alleles, incl REF (index 0) - which is missing from the ALT list, so we add +1 

                # The locus must match our rule (we ignore if the ALT alle was actually called for now - CHECK AND FIX!)
                if is_match(ref_allele, alt_allele):  # rule_string == allele_string:  # and str(this_index) in genotypes:

                    has_matched = True

                    this_match["report"] = rule["positive_report"]

                    if genotype_string == "0/0" or genotype_string == "./.":
                        this_match["comment"] = "No variant allele called!"

                    acov += coverages[this_index]  # the coverage for this ALT allele

            if acov > 0:
                # The VCF coverage is wrong since it counts overlapping PE reads independently
                # We check if we have correctly determined coverages and correct, if so
                if this_cov != "NA":
                    rfrac = float(rcov) / float(cov_sum)
                    afrac = float(acov) / float(cov_sum)
                    rcov = round((rfrac * this_cov), 0)
                    acov = round((afrac * this_cov), 0)
                    cov_sum = this_cov

                perc = (float(acov) / float(cov_sum)) * 100.0

                this_match["perc_gmo"] = round(perc, 2)
                this_match["ref_cov"] = rcov
                this_match["alt_cov"] = acov
                this_match["vcf_cov"] = cov_sum
                this_match["genotye"] = genotype_string

                result["matches"].append(this_match)

        # Nothing has matched at all, so we return a placeholder
        if not has_matched:
            this_match["report"] = rule["negative_report"]
            this_match["ref_cov"] = "NA"
            this_match["alt_cov"] = "NA"
            this_match["vcf_cov"] = "NA"
            this_match["perc_gmo"] = 0.0
            this_match["genotype_string"] = "NA"

            result["matches"].append(this_match)

    with open(output, "w") as fo:
        json.dump(result, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.sample, args.vcf, args.json, args.coverage, args.output)
