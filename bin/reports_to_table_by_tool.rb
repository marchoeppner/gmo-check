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
opts.banner = "Reads reports and makes an Excel table with one sheet per analysis rule"
opts.separator ""
opts.on("-o","--outfile", "=OUTFILE","Output file") {|argument| options.outfile = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

negative_result = "-"

files = Dir["*.json"]

bucket = {}

toolchain = nil

files.each do |file|

    json = parse_json(file)
    matches = json["matches"]

    matches.each do |match|

        rule = match["rule"]
        match["Sample"] = json["sample"]

        bucket.has_key?(rule) ? bucket[rule] << match : bucket[rule] = [ match ]

    end

end

# a bucket is a rule with all the matching reports, i.e. one page
bucket.each do |rule,reports|

    csv_list = []

    this_row = []
    row = 0
    col = 0

    # The table header
    [ "Probe", "Abdeckung WT (%)", "Abdeckung GMO (%)"].each do |e|
        this_row << e
        col += 1
    end
    csv_list << this_row

    # Each sample with all its reports (max 2)
    reports.sort_by{|r| r["sample"]}.each do |r|

        this_row = []

        row += 1
        col = 0

        sample = r["Sample"]

        this_row << sample

        col += 1

        ref_cov = r["ref_cov"]
        
        if ref_cov == "NA"
            ref_cov = r["bam_cov"] if r.has_key?("bam_cov")
        end

        perc_gmo = r["perc_gmo"]

        this_row << ref_cov
        alt_cov = r["alt_cov"]
        this_row << alt_cov
    
        toolchain = r["toolchain"]

        csv_list << this_row

    end

    header = [ "# id: 'gmo_check_result_#{toolchain}'",
        "# section_name: '#{rule} (#{toolchain})'",
        "# description: 'GMO Nachweis für #{rule} (Anteil in %).'",
        "# format: 'tsv'",
        "# plot_type: 'table'",
        "# pconfig:",
        "#    id: 'custom_bargraph_w_header'",
        "#    ylab: 'Anteil GMO'" ]

    file_name = rule.gsub(" ","_").downcase
    file = File.new(file_name +"_mqc.tsv","w+")

    file.puts header.join("\n")

    csv_list.each do |entry|

        file.puts entry.join("\t")

    end

    file.close
    
end




