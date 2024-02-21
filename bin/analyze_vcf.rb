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
opts.on("-s","--sample", "=SAMPLE","Sample name") {|argument| options.sample = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

date = Time.now.strftime("%Y-%m-%d")

result = { "sample" => options.sample, "matches" => [] }

json = JSON.parse(IO.readlines(options.json).join)

rules = json["rules"]["bwa-freebayes"]["payload"]

vcf = parse_vcf(options.vcf)

rules.each do  |rule|
    
    rule_name = rule["name"]
    rule_string = rule["matcher"]

    this_match = { "toolchain" => "bwa2" , "rule" => rule_name}

    has_matched = false

    vcf.each do |entry|
        
        allele_string = entry.allele_string
        this_sample = entry.samples[0]

        # A match, presumably
        if rule_string == allele_string

            has_matched = true

            this_match["report"] = rule["positive_report"]

            genotype = this_sample["GT"]

            if genotype == "0/0"
                this_match["comment"] = "Variantenfrequenz unter Call-Schwelle!"
            end

            rcov,acov = this_sample["AD"].split(",")
            cov_sum = acov.to_i + rcov.to_i
            perc = (acov.to_f / cov_sum.to_f)*100.0
            this_match["perc_gmo"] = perc.round(2)
            this_match["ref_cov"] = rcov
            this_match["alt_cov"] = acov

            result["matches"] << this_match

        end
    end

    unless has_matched
        this_match["report"] = rule["negative_report"]
        result["matches"] << this_match
    end

end

puts result.to_json
