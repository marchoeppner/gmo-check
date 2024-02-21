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
opts.on("-o","--outfile", "=OUTFILE","Output file") {|argument| options.outfile = argument }
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

workbook = RubyXL::Workbook.new
page = 0

bucket.each do |rule,reports|

    sheet = workbook.worksheets[page]
    sheet.sheet_name = rule
    
    row = 0
    col = 0

    sheet.add_cell(row,col,"Probe")
    col += 1
    sheet.add_cell(row,col,"Vsearch/Blast")
    col += 1
    sheet.add_cell(row,col,"Bwa2/Freebayes")

    
    reports.group_by{|r| r["Sample"]}.sort.each do |sample,data|

        row += 1
        col = 0
        
        sheet.add_cell(row,col,sample)
        col += 1

        blast = data.find{|d| d["Befund"].include?("Amplicon")}
        freebayes = data.find{|d| d["Befund"].include?("Varianten")}

        blast ? b = blast["Anteil Variante %"] : b = "Kein Nachweis"
        # Here we remove noisy results below 1%
        if !b.to_s.include?("Nachweis")
            b = "Kein Nachweis" if b.to_f < 1.0
        end
        freebayes ? f = freebayes["Anteil Variante %"] : f = "Kein Nachweis"

        sheet.add_cell(row,col,b)
        col += 1

        sheet.add_cell(row,col,f)

    end

    page += 1

end

workbook.write(options.outfile)


