#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import argparse

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--sample", help="The sample name")
parser.add_argument("--blast", help="A blast report in JSON format")
parser.add_argument("--json", help="AA rule set in JSON format")
parser.add_argument("--output")

args = parser.parse_args()


def main(sample, blast_data, ref_data, output):

    # Initialize the data dict
    data = {"sample": sample, "matches": []}

    # Parse the JSON file
    with open(ref_data) as f:
        refs = json.load(f)

    # Read the rules for OTUs/Blast
    rules = refs["rules"]["vsearch-blast"]["payload"]

    # Open the BLAST report
    with open(blast_data) as f:
        blast = json.load(f)

    # Read the Blast reports
    reports = blast["BlastOutput2"]

    total_cov = 0
    carrier_cov = 0

    for rule in rules:

        total_cov = 0

        rule_name = rule["name"]
        rule_string = rule["matcher"]

        has_matched = False

        for report in reports:

            r = report["report"]
            results = r["results"]["search"]
            query_string = results["query_title"]
            query, coverage_string = query_string.split(";")
            coverage = int(coverage_string.replace("size=", ""))

            total_cov += coverage
            hits = results["hits"]

            for hit in hits:

                for hsp in hit["hsps"]:
                    target_seq = hsp["hseq"]

                    if rule_string in target_seq:
                        has_matched = True
                        carrier_cov += coverage

        if has_matched:
            perc = (float(carrier_cov) / float(total_cov)) * 100
            data["matches"].append({"rule": rule_name, "toolchain": "vsearch", "result": rule["positive_report"], "perc_gmo": round(perc, 2), "ref_cov": (total_cov - carrier_cov), "alt_cov": carrier_cov})
        else:
            data["matches"].append({"rule": rule_name, "toolchain": "vsearch", "result": rule["negative_report"], "perc_gmo": 0, "ref_cov": total_cov, "alt_cov": "NA"})

    with open(output, "w") as fo:
        json.dump(data, fo, indent=4, sort_keys=True)


if __name__ == '__main__':
    main(args.sample, args.blast, args.json, args.output)
