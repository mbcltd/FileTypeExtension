require 'fileutils'

if ARGV.length != 2
  puts "Usage file_type_extension.rb source_dir output_dir"
  exit 1
end

$source_directory = ARGV[0]
$output_directory = ARGV[1]

puts "Getting all files under directory: #{$source_directory}"

# Get all of the files and directories recursively under the source directory as a directory
all_files = Dir["#{$source_directory}/**/*"]

# Filter out the directories so that we're just left with the files
files = all_files.filter{ |f| File.file?(f) }

# 'Hash' of the mappings between the first word response of the file command to an extension
$file_extensions = Hash[
  "PDF" => "pdf",
  "ASCII" => "txt",
  "PNG" => "png",
  "JPEG" => "jpg"
]

def extension_for_file(file)
  # Execute the file command against this particular file
  file_type = `file -b #{file}`
  # Look up the extension based upon the first word of the output of the file command
  extension = $file_extensions[file_type.split.first]
  # Return the extension that we have found
  if extension != nil
    ".#{extension}"
  else file_type
  end
end

puts "Analysing extensions of files based on their file types"

# Work out the extensions for all of the files
all_extensions = files.map{ |f| extension_for_file(f) }.uniq.sort

# Find any extensions which are errors (don't begin with a dot)
all_errors = all_extensions.filter{ |x| !x.start_with?(".") }

if all_errors.length > 0
  # Oh no, there are files where we can't work out the extension, let's bail
  puts "Could not find extensions for all file types:"
  puts all_errors.map { |t| " - #{t}" }
  exit 1
else
  # Everything is good
  puts "All extensions identified successfully"
end

def process(file)
  # Get the extension again
  extension = extension_for_file(file)

  # Replace the source directory with the output directory to work out where the new file should go
  target_file_loc = file.sub($source_directory, $output_directory)

  # Add the file extension if necessary
  target_file = if target_file_loc.end_with?(extension)
                  target_file_loc
                else
                  "#{target_file_loc}#{extension}"
                end

  # Work out where the target directory is
  target_dir = File.dirname(target_file)

  # Create the target directory if necessary
  unless File.directory?(target_dir)
    FileUtils.mkdir_p(target_dir)
  end

  # Copy the original file to the target file name
  FileUtils.cp(file, target_file)
end

puts "Processing all files into the output directory: #{$output_directory}"

# Process all of the files
files.each { |f| process(f) }

puts "Processing complete"
