#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'

### Define modules and classes here

def parse_json(filename)

    return JSON.parse(IO.readlines(filename).join)

end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Extracts BED formatted calling regions from json"
opts.separator ""
opts.on("-j","--json", "=JSON","JSON file") {|argument| options.json = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

json = parse_json(options.json)

rules = json["rules"]["bwa-freebayes"]["payload"]

rules.each do |rule|

    name = rule["name"]
    target = rule["target"].split(":")

    seq = target.shift
    from,to = target.shift.split("-").collect{|t| t.to_i }

    puts "#{seq}\t#{from-1}\t#{to+1}\t#{name}"

end


