#!/usr/bin/env ruby

require 'write_xlsx'

def debug(*args)
  STDERR.puts(*args)
end

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
  File.open(file_path).each do |line|
    if line =~ /\/\*.*\*\//
      # do nothing
    elsif line =~ /.*=.*/
      line = line.gsub(/\"/, "")
      current_list = []
      current_list.push(nib_filename)
      current_list.push(line.split("=")[0])
      current_list.push(line.split("=")[1].chomp.chomp(';'))
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
  worksheet.write_col('A1', [['filename', 'key', 'value']],
                      format)
end

def extract_strings_from_dir dir
  filenames = filter_files Dir.entries(dir), dir
  nib_filenames = filter_nib_filenames filenames

  workbook = WriteXLSX.new("Translations-#{dir.split("/").last}.xlsx")
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

  p rows
 
  worksheet.write_col('A2', rows)

  workbook.close
end

def extract_language_dir_from_ipa ipa
  debug "Unzipping ipa"
  system "rm -rf Payload"
  system "unzip -q #{ipa}"

  app = Dir.glob("Payload/*.app")[0]
  proj_dirs = Dir.glob("#{app}/*.lproj")
  proj_dirs.select do |proj_dir|
    !(proj_dir.eql? "#{app}/Base.lproj")
  end
end

if __FILE__ == $0
  language_dirs = extract_language_dir_from_ipa "/Users/yatin/projects/ios-localized-strings-extrator/App.ipa"
  debug language_dirs

  language_dirs.each do |dir|
    extract_strings_from_dir dir
  end
end

