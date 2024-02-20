#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'

### Define modules and classes here

class VCFEntry

    attr_accessor :seq, :pos, :id, :ref, :alt, :qual, :filter, :info, :format, :samples, :sample_names

    def initialize(string,header)
        # #CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	S100
        elements = string.strip.split("\t")
        @seq,@pos,@id,@ref,@alt,@qual,@filter,info,format, = elements[0..8]
        @info = {}
        info.split(";").each do |i|
            key,value = i.split("=")
            @info[key] = value
        end
        @format = format.split(":")

        @samples = []
        @sample_names = header[9..-1]
        elements[9..-1].each_with_index do |sample,i|
            sample_elements = sample.split(":")
            sample_data = {}
            @format.each_with_index do |k,i|
                val = sample_elements[i]
                sample_data[k] = val
            end
            @samples << sample_data 
        end
    end

    def allele_string
        return "#{self.seq}\t#{self.pos}\t.\t#{self.ref}\t#{self.alt}"
    end

end

def parse_vcf(file)

    data =  []

    header = []

    vcf = File.open(file)

    while (line = vcf.gets)

        next if line.match(/^##.*/)

        if line.match(/^#CHROM.*/)
            header = line.split("\t").collect{|k| k.strip }
        else 
            entry = VCFEntry.new(line,header)
            data << entry
        end
    end

    vcf.close

    return data
end

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Reads Fastq files from a folder and writes a sample sheet to STDOUT"
opts.separator ""
opts.on("-v","--vcf", "=VCF","VCF to read") {|argument| options.vcf = argument }
opts.on("-j","--json", "=JSON","JSON to read") {|argument| options.json = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

date = Time.now.strftime("%Y-%m-%d")

json = JSON.parse(IO.readlines(options.json).join)

rules = json["rules"]["bwa-freebayes"]["payload"]

vcf = parse_vcf(options.vcf)

vcf.each do |entry|

    allele = entry.allele_string

    sample_name = entry.sample_names[0]
    puts ">>>" + sample_name + "<<<"

    has_matched = false

    rules.each do |rule|
        string = rule["matcher"]
        if string == allele
            has_matched = true
            
            puts rule["yields"]
            sample = entry.samples[0]
            genotype = sample["GT"]
            if genotype == "0/0"
                puts "Varianten Frequenz unter Detektierungsschwelle!"
            end
            rcov,acov = sample["AD"].split(",")
            perc = (acov.to_f / rcov.to_f)*100.0
            puts "\tGenotyp: #{sample["GT"]}\tAnteil: #{perc.round(2)}%\tRef: #{rcov}\tAlt: #{acov}\t"

        end
    end
    
    if !has_matched
        puts "Keine GABA Mutation nachgewiesen!"
    end

    puts "==============================================================================="

end