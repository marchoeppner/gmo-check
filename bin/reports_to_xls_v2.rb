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

toolchains = []

bucket = {}

files.each do |file|

    json        = parse_json(file)
    sample      = json["sample"]
    matches     = json["matches"]

    matches.each do |match|

        toolchain   = match["toolchain"]
        rule        = match["rule"]

        toolchains << toolchain unless toolchains.include?(toolchain)

        bucket[rule] = {} unless bucket.has_key?(rule)

        bucket[rule].has_key?(sample) ? bucket[rule][sample] << match : bucket[rule][sample] = [ match ]

    end

end

toolchains.sort!

workbook = RubyXL::Workbook.new
page = 0

# a bucket is a rule with all the matching reports, i.e. one page
bucket.each do |rule,samples|

    sheet = workbook.worksheets[page]
    sheet.sheet_name = rule

    row = 0
    col = 0

    [ "" ].push(toolchains.map { |tc| [ tc, "", ""] }).flatten.each do |tc|
        sheet.add_cell(row,col,tc)
        sheet.sheet_data[row][col].change_font_bold(true)
        sheet.change_column_width(col, 15)
        col += 1
    end
    row += 1
    col = 0

    [ "Probe" ].push(toolchains.map{|tc| [ "% GMO","Reads WT","Reads GMO"]}).flatten.each do |tc|
        sheet.add_cell(row,col,tc)
        sheet.sheet_data[row][col].change_font_bold(true)
        sheet.change_column_width(col, 15)
        col += 1
    end

    samples.each do |sample,reports|

        row += 1
        col = 0

        sheet.add_cell(row,col,sample)
        col += 1

        failed = false

        toolchains.each do |tool|

            perc_gmo = ""
            ref_cov = ""
            alt_cov = ""

            report = reports.find{|r| r["toolchain"] == tool }

            if report
                perc_gmo = report["perc_gmo"]
                ref_cov = report["ref_cov"]
                alt_cov = report["alt_cov"]
                if ref_cov == "NA" && report.has_key?("bam_cov")
                    ref_cov = report["bam_cov"]
                    alt_cov = "-"
                end
            end

            # Simplistic rule to catch failed samples. 
            if ref_cov.to_i < 100
                failed = true
            end

            [ perc_gmo, ref_cov, alt_cov].each do |e|
                sheet.add_cell(row,col,e)
                col += 1
            end


        end

        if failed
            sheet.change_row_fill(row,"FF3300")
        else
            row.even? ? bg = color["even"] : bg = color["uneven"]
            sheet.change_row_fill(row, bg)
        end
        sheet.change_row_horizontal_alignment(row, 'right')

    end
    
    col = 0
    toolchains.each do |tc|
        sheet.change_column_border(col, :right, 'medium')
        col += 3
    end
    
    sheet.change_row_border(0, :bottom, 'medium')  

    # increment page counter for the next rule, if any
    page += 1

end

workbook.write(options.outfile)


