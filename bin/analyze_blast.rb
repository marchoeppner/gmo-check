#!/bin/env ruby

require 'optparse'
require 'ostruct'
require 'json'

### Define modules and classes here

### Get the script arguments and open relevant files
options = OpenStruct.new()
opts = OptionParser.new()
opts.banner = "Reads Fastq files from a folder and writes a sample sheet to STDOUT"
opts.separator ""
opts.on("-b","--blast", "=BLAST","Blast report to read") {|argument| options.blast = argument }
opts.on("-j","--json", "=JSON","JSON to read") {|argument| options.json = argument }
opts.on("-s","--sample", "=SAMPLE","Sample name") {|argument| options.sample = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

# we ignore any results below this coverage
min_coverage = 100

output = { "sample" => options.sample, "matches" => [] }

date = Time.now.strftime("%Y-%m-%d")

json = JSON.parse(IO.readlines(options.json).join)

rules = json["rules"]["vsearch-blast"]["payload"]

blast = JSON.parse(IO.readlines(options.blast).join)

reports = blast["BlastOutput2"]

findings = []
total_cov = 0
carrier_cov = 0

rules.each do |rule|

    total_cov = 0
    query_cov = 0

    rule_name = rule["name"]
    rule_string = rule["matcher"]

    has_matched = false
    reports.each do |r|

        report = r["report"]
        results = report["results"]["search"]

        query_string = results["query_title"]

        query,coverage = query_string.split(";")
        coverage = coverage.gsub("size=", "").to_i
    
        total_cov += coverage
    
        hits = results["hits"]
    
        hits.each do |hit|
    
            target = hit["description"][0]["title"]

            warn "Not the right target...!" unless target == rule["target"]
    
            hsps = hit["hsps"]
    
            hsps.each do |hsp|
                target_seq = hsp["hseq"]

                if target_seq.include?(rule_string)
                    has_matched = true
                    carrier_cov += coverage
                end
    
            end
        end

    end

    if has_matched
        perc = (carrier_cov.to_f / total_cov.to_f) * 100
        output["matches"] << { "rule" => rule_name , "toolchain" => "vsearch", "result" => rule["positive_report"], "perc_gmo" => perc.round(2), "ref_cov" => total_cov-carrier_cov, "alt_cov" => carrier_cov }
    else
        output["matches"] << { "rule" => rule_name , "toolchain" => "vsearch", "result" => rule["negative_report"], "ref_cov" => total_cov, "alt_cov" => "NA" }
    end

end

puts output.to_json