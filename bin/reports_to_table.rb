#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'
require 'csv'

### Define modules and classes here

def parse_json(filename)

    return JSON.parse(IO.readlines(filename).join)

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Reads reports and makes a table"
opts.separator ""
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

files = Dir["*.json"]

rows = []

header = [ "Sample", "Blast", "Freebayes" ]

rows << header

files.group_by{|f| f.split(".")[0..-3].join}.each do |group,reports|

    blast = reports.find {|r| r.include?("blast.json")}
    freebaytes = reports.find { |r| r.include?("freebayes.json")}

    this_data = []

    sample = group
    this_data << sample

    if blast
        json = parse_json(blast)
        matches = json["matches"]
        this_data << matches[0]["Befund"]
    else
        this_data << ""
    end

    if freebayes
        json = parse_json(freebayes)
        matches = json["matches"]
        this_data << matches[0]["Befund"]
    else
        this_data << ""
    end

    rows << this_data

end

File.write("summary_mqc.csv", rows.map(&:to_csv).join)




