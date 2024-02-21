#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'
require 'rubyXL'
require 'rubyXL/convenience_methods/cell'
require 'rubyXL/convenience_methods/color'
require 'rubyXL/convenience_methods/font'
require 'rubyXL/convenience_methods/workbook'
require 'rubyXL/convenience_methods/worksheet'


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

bucket = {}

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

bucket.each do |rule,reports|

    reports.group_by{|r| r["Sample"]}.sort.each do |sample,data|

        puts sample

    end
end




