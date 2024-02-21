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

# awfully convuluted way to bin all the reports by rule and sample name
files.group_by{|f| f.split(".")[0..-3].join}.each do |group,reports|

    blast = reports.find {|r| r.include?(".blast.")}
    freebayes = reports.find { |r| r.include?(".freebayes.")}

    this_data = []

    if blast
        json = parse_json(blast)
        matches = json["matches"]

        matches.each do |match|
            rule = match["rule"]
            match["Sample"] = json["sample"]

            bucket.has_key?(rule) ? bucket[rule] << match : bucket[rule] = [ match ]
        end

    end

    if freebayes
        json = parse_json(freebayes)
        matches = json["matches"]
        matches.each do |match|
            rule = match["rule"]
            match["Sample"] = json["sample"]
            bucket.has_key?(rule) ? bucket[rule] << match : bucket[rule] = [ match ]
        end
    end

end


# a bucket is a rule with all the matching reports, i.e. one page
bucket.each do |rule,reports|

    csv_list = []

    this_row = []
    row = 0
    col = 0

    # The table header
    [ "Probe", "Vsearch/Blast", "Bwa2/Freebayes"].each do |e|
        this_row << e
        col += 1
    end

    csv_list << this_row
    # Each sample with all its reports (max 2)
    reports.group_by{|r| r["Sample"]}.sort.each do |sample,data|

        this_row = []

        row += 1
        col = 0
        
        this_row << sample

        col += 1
        
        blast = data.find{ |d| d["toolchain"].include?("vsearch")}
        freebayes = data.find{ |d| d["toolchain"].include?("bwa2")}

        blast ? b = blast["perc_gmo"] : b = negative_result
        # Here we remove noisy results below 1%
        if b.is_a?(Float)
            b = negative_result if b.to_f < 1.0
        end

        if freebayes
            freebayes.has_key?("perc_gmo") ? f = freebayes["perc_gmo"] : f = negative_result
        else
            f = "N/A"
        end

        this_row << b
        this_row << f

        csv_list << this_row

    end

    header = [ "# id: 'gmo_check_result'",
        "# section_name: '#{rule}'",
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




