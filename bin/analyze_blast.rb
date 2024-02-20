#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'nokogiri'

### Define modules and classes here

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Reads Fastq files from a folder and writes a sample sheet to STDOUT"
opts.separator ""
opts.on("-b","--blast", "=BLAST","Blast report to read") {|argument| options.vcf = argument }
opts.on("-j","--json", "=JSON","JSON to read") {|argument| options.json = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

date = Time.now.strftime("%Y-%m-%d")

file = File.open(options.blast)

xml = Nokogiri::XML(file)

