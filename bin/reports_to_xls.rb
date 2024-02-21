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
opts.banner = "Reads reports and makes an Excel table with one sheet per analysis rule"
opts.separator ""
opts.on("-o","--outfile", "=OUTFILE","Output file") {|argument| options.outfile = argument }
opts.on("-h","--help","Display the usage information") {
    puts opts
    exit
}

opts.parse! 

color = {
	"even" => "FFFFFF",
	"uneven" => "d4e6f1"
}

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

workbook = RubyXL::Workbook.new
page = 0

# a bucket is a rule with all the matching reports, i.e. one page
bucket.each do |rule,reports|

    sheet = workbook.worksheets[page]
    sheet.sheet_name = rule
    
    row = 0
    col = 0

    # The table header
    [ "Probe", "Vsearch/Blast", "Bwa2/Freebayes"].each do |e|
        sheet.add_cell(row,col,e)
        sheet.sheet_data[row][col].change_font_bold(true)
        sheet.change_column_width(col, 15)
        col += 1
    end

    # Each sample with all its reports (max 2)
    reports.group_by{|r| r["Sample"]}.sort.each do |sample,data|

        row += 1
        col = 0
        
        sheet.add_cell(row,col,sample)
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

        sheet.add_cell(row,col,b)
        col += 1

        sheet.add_cell(row,col,f)

        row.even? ? bg = color["even"] : bg = color["uneven"]
		sheet.change_row_fill(row, bg)
        sheet.change_row_horizontal_alignment(row, 'right')
    end

    sheet.change_column_border(0, :right, 'medium')
    sheet.change_row_border(0, :bottom, 'medium')  

    # increment page counter for the next rule, if any
    page += 1

end

workbook.write(options.outfile)


