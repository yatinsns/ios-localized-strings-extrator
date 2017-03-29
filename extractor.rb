#!/usr/bin/env ruby

require 'write_xlsx'

def filter_files filenames, dir
  filenames.select do |filename|
    File.file?("#{dir}/#{filename}")
  end
end

def filter_nib_filenames filenames
  filenames.select do |filename|
    !(filename == "Localizable.strings") && !(filename == "InfoPlist.strings")
  end
end

def parse nib_filename, dir
  printf "#{nib_filename}:\n"
  file_path = "#{dir}/#{nib_filename}"

  lists = []
  current_list = []
  File.open(file_path).each do |line|
    if line =~ /\/\*.*\*\//
      line = line.gsub(/\s+/, "")
      line = line.gsub(/\/\*/, "")
      line = line.gsub(/\*\//, "")

      results = []
      line.split(";").each_with_index do |split_value, index|
        results.push split_value.split("=")[0] if index == 1
        results.push split_value.split("=")[1]
      end
      current_list = results.unshift(nib_filename)
    elsif line =~ /.*=.*/
      line = line.gsub(/\s+/, "")
      current_list.push(line.split("=")[0])
      current_list.push(line.split("=")[1])
      lists.push(current_list)
    end
  end
  lists
end

def header_format_in_workbook workbook
  format = workbook.add_format
  format.set_bold
  format.set_color('black')
  format.set_align('center')
  format
end

def insert_headers_in_worksheet worksheet, format
  worksheet.write_col('A1', [['filename', 'Class', 'Param', 'English text', 'ObjectID', 'key', 'value']],
                      format)
end

def extract_strings_from_dir dir
  filenames = filter_files Dir.entries(dir), dir
  nib_filenames = filter_nib_filenames filenames

  workbook = WriteXLSX.new("Translations.xlsx")
  worksheet = workbook.add_worksheet

  header_format = header_format_in_workbook workbook
  insert_headers_in_worksheet worksheet, header_format
  
  results = nib_filenames.map do |nib_filename|
    parse nib_filename, dir
  end

  rows = []
  results.each do |file_data|
    file_data.each do |file_row_data|
      rows.push file_row_data
    end
  end

  worksheet.write_col('A2', rows)

  workbook.close
end

if __FILE__ == $0
  extract_strings_from_dir "/Users/yatin/directi/Pingpong-iOS/Resources/es.lproj"
end

