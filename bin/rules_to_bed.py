#!/usr/bin/env python3
# -*- coding: utf-8 -*-


import argparse
import json

parser = argparse.ArgumentParser(description="Script options")
parser.add_argument("--json", help="An rule set in JSON format")
parser.add_argument("--output")
args = parser.parse_args()


def main(json_file, output):

    # Parse the JSON file
    with open(json_file) as f:
        refs = json.load(f)

    rules = refs["rules"]["bwa-freebayes"]["payload"]

    with open(output, "w") as fo:
        for rule in rules:

            name = rule["name"]
            target = rule["target"].split(":")

            seq = target.shift
            seq_from,seq_to = [ int(i) for i in target.pop(0).split("-") ]
            fo.write(f"{seq}\t{seq_from-1}\t{seq_to+1}\t{name}\n")


if __name__ == '__main__':
    main(args.json, args.output)
