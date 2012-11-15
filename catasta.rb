require 'yaml'
require 'benchmark'
require 'optparse'
require 'pathname'

require 'term/ansicolor'
class String
  include Term::ANSIColor
end

require_relative "core/app"

options = {
  header: true
}
input_file = nil
output_directory = nil
op = OptionParser.new do |opts|
  opts.banner = "Usage: ruby #$0 [options] file"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-t", "--type=TYPE", "Type to output, e.g. Java15, Ruby.") do |t|
    options[:type] = t
  end
  opts.on("--[no-]header", "Enable or disable the header at the top of generated files.") do |h|
    options[:header] = h
  end
  # No argument, shows at tail.  This will print an options summary.
  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end
op.parse!

input_file = ARGV.shift
output_directory = ARGV.shift

unless File.exist? input_file
  $stderr.puts "File not found: `#{input_file}`"
  exit
end

Catasta::App.new(options).go(input_file, output_directory)