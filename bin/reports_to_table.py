#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import glob
import json

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--output")
args = parser.parse_args()


def main(output):

    reports = sorted(glob.glob("*.json"))
    bucket = {}
    toolchains = [ "vsearch", "bwa2"]

    for report in reports:

        # Parse the JSON file
        with open(report) as f:
            refs = json.load(f)

        sample = refs["sample"]
        matches = refs["matches"]
        
        for match in matches:
            rule = match["rule"]
            match["Sample"] = sample
            if rule in bucket:
                bucket[rule].append(match)
            else:
                bucket[rule] = [ match ]

    for rule, matches in bucket.items():

        header = [ "# id: 'gmo_check_result'",
            "# section_name: '#{rule}'",
            "# description: 'GMO Nachweis für #{rule} (Anteil in %).'",
            "# format: 'tsv'",
            "# plot_type: 'table'",
            "# pconfig:",
            "#    id: 'custom_bargraph_w_header'",
            "#    ylab: 'Anteil GMO'" ]
        
        csv_list = []

        this_row = []
        row = 0
        col = 0

        # The table header
        for entry in [ "Probe", "Vsearch/Blast", "Bwa2/Freebayes"]:
            this_row.append(entry)
            col += 1

        csv_list.append(this_row)

        grouped_reports = {}
        for match in matches:
            sample = match["Sample"]
            if sample in grouped_reports:
                grouped_reports[sample].append(match)
            else:
                grouped_reports[sample] = [ match ]

    
        for sample,reports in grouped_reports.items():
            this_row = []
            row += 1
            col = 0

            this_row.append(sample)

            col += 1

            for toolchain in toolchains:
                # Check if we have an entry for this tool chain
                data = next((item for item in reports if item["toolchain"] == toolchain ),None)
                if data:
                    this_row.append(str(data["perc_gmo"]))
                else:
                    this_row.append("-")
            
            csv_list.append(this_row)

        rule_name = rule.lower().replace(" ", "_")
        this_result = f"{rule_name}_mqc.tsv"
        with open(this_result, "w") as fo:
            fo.write("\n".join(header)+ "\n")
            for row in csv_list:
                entry = "\t".join(row)
                fo.write(entry+ "\n")
        

if __name__ == '__main__':
    main(args.output)
