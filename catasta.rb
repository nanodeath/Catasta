require 'yaml'
require 'benchmark'
require 'optparse'
require 'pathname'
require 'pry' 

require 'term/ansicolor'
class String
  include Term::ANSIColor
end

require_relative 'common/parser'
require_relative 'optimizers/adjacent_text_optimizer'
require_relative 'ruby/generator'
require_relative 'ruby/writer'
require_relative 'ruby/template'
require_relative 'java15/generator'
require_relative 'java15/writer'
require_relative 'javascript5/generator'
require_relative 'javascript5/writer'

module CurlyCurly
  VERSION = "0.1"

  class SourceVisitor
    def initialize
      @source = {}
    end
    def visit_line(line, line_number)
      @source[line_number_to_key(line_number)] = line
    end
    def get_line(line_number)
      @source[line_number_to_key(line_number)]
    end

    private
    def line_number_to_key(line_number)
      :"line_#{line_number}"
    end
  end

  class Catasta
    attr_reader :input_folder
    attr_reader :config
    attr_reader :output
    attr_reader :generators
    attr_reader :writers

    def initialize(input_folder, output, ops={})
      @input_folder = input_folder
      @output = output
      @ops = ops

      @config = if File.exist?(File.join(@input_folder, "catasta.yml"))
        YAML::load(File.read(File.join(@input_folder, "catasta.yml"))).merge(@ops)
      else
        @ops
      end

      # validate
      if !File.directory? @input_folder
        raise "#{@input_folder} doesn't exist or isn't a directory"
      end
      if(@output != "-")
        FileUtils.mkdir_p @output
      end
    end

    def go!
      #process_frontmatter
      #simplify_embedded_logic
      #parse
      Dir[File.join(@input_folder, "**", "*.cts")].each do |file|
        TemplateProcessor.new(self, file).process!
      end
    end
  end

  class TemplateProcessor
    attr_reader :commands
    attr_reader :root_folder
    attr_reader :path

    def initialize(catasta, path)
      @source = File.read(path).gsub(/\r\n|\r/, "\n")
      @root_folder = catasta.input_folder
      @path = path
      @output = catasta.output
      @processed = false
      @config = catasta.config
      @catasta = catasta
    end
    def process!
      raise if @processed
      @processed = true

      process_frontmatter
      simplify_embedded_logic
      parse

      go_ruby if @config["targets"].include? "Ruby"
    end

    def process_frontmatter
      # Extract the "raw" front matter from the template, removing it from the source
      @source.gsub!(/^(---.*)---\n/m) {|m| @raw_front_matter = YAML.load_documents(m); ""}
      # Create a new hash containing the contents of the raw front matter, keyed off of target
      @front_matter = @raw_front_matter.compact.inject({}){|memo, doc| memo[doc["target"]] = doc; memo}
      # Reasonable defaults
      @front_matter[nil] = {
        "header" => true
      }.merge(@front_matter[nil])
      # Merge the default content (unspecified target) into each target's config
      @front_matter.each do |target, doc|
        next if target.nil?
        doc.replace(@front_matter[nil].merge(doc))
      end
      # Ensure there's at least the default content for each target specified in the core config file
      @config["targets"].each do |target|
        if @front_matter[target].nil?
          @front_matter[target] = @front_matter[nil].dup
        end
      end
    end

    def simplify_embedded_logic
      @commands = []
      @cleaned = @source.gsub(/{{(.+?)}}/) {|m| @commands.push($1); "{{#{@commands.size-1}}}"}
    end
    def parse
      @parser = Parser.new(self)
      sv = SourceVisitor.new
      visitors = [sv, p]

      @source.split("\n").each_with_index do |line, idx|
        sv.visit_line(line, idx+1)
      end

      @cleaned.split("\n").each_with_index do |line, idx|
        @parser.visit_line(line, idx+1)
      end

      sexp = nil
      core_optimizers = [AdjacentTextOptimizer.new]
      core_optimizers.each {|o| o.optimize! @parser.get}

      @write_args = {to_directory: Pathname.new(@output).dirname.to_s}
    end

    def go_ruby
      catasta.generators[:ruby] ||= Ruby::Generator.new
      generated = catasta.generators[:ruby].process(@parser.get_tree)
      catasta.writers[:ruby] ||= Ruby::Writer.new
      catasta.writers[:ruby].process(@write_args, generated, @config)
    end
  end

  class Curly
    attr_reader :commands
    attr_reader :front_matter

    def initialize(input_file, output_file, ops={})
      @input_file = input_file
      @output_file = output_file
      @ops = ops
      @template = File.read(@input_file)

      @commands = []
      @front_matter = {}
    end

    def go!
      process_frontmatter
      parse
    end

    private
    def process_frontmatter
      @template.gsub!(/^(---.*)---\n/m) {|m| @front_matter = YAML.load_documents(m); ""}
      @front_matter = @front_matter.compact.inject({}){|memo, doc| memo[doc["target"]] = doc; memo}
      (@front_matter[nil] ||= {})["header"] = @ops[:header]
      @front_matter.each do |target, doc|
        next if target.nil?
        doc.replace(@front_matter[nil].merge(doc))
      end
    end

    def parse
      cleaned = @template.gsub(/{{(.+?)}}/) {|m| @commands.push($1); "{{#{@commands.size-1}}}"}

      p = Parser.new(self)
      sv = SourceVisitor.new
      visitors = [sv, p]

      @template.split("\n").each_with_index do |line, idx|
        sv.visit_line(line, idx+1)
      end

      cleaned.split("\n").each_with_index do |line, idx|
        p.visit_line(line, idx+1)
      end

      sexp = nil
      core_optimizers = [AdjacentTextOptimizer.new]
      core_optimizers.each {|o| o.optimize! p.get}

      write_args = if @output_file
        {to_file: @output_file}
      else
        {to_directory: Pathname.new(@input_file).dirname.to_s}
      end
      
      if @ops[:type].nil? || @ops[:type] == "Ruby"
        ruby_code = Ruby::Generator.new(self, @front_matter["Ruby"], p).process
        Ruby::Writer.new(@front_matter["Ruby"], ruby_code[:imports], ruby_code[:code], ruby_code[:class_code]).write(write_args)
      end
      if @ops[:type].nil? || @ops[:type] == "Java15"
        java_code = nil
        if @front_matter["Java15"]
          begin
            java_code = Java15::Generator.new(self, @front_matter["Java15"], p).process
          rescue CompileError => exception
            puts
            puts "Error: " + exception.message.on_red
            puts "   " + sv.get_line(exception.line_number-2)
            puts "   " + sv.get_line(exception.line_number-1)
            puts ">> " + sv.get_line(exception.line_number).red
            puts "   " + sv.get_line(exception.line_number+1)
            puts "   " + sv.get_line(exception.line_number+2)
            exit 1
          end

          Java15::Writer.new(@front_matter["Java15"], java_code[:imports], java_code[:code], java_code[:class_code]).write(write_args)
        end
      end
      if @ops[:type].nil? || @ops[:type] == "JavaScript5"
        js_code = nil
        if @front_matter["Javascript5"]
            js_code = ::CurlyCurly::Javascript5::Generator.new(self, @front_matter["Javascript5"], p).process
            Javascript5::Writer.new(@front_matter["Javascript5"], js_code[:code], js_code[:class_code]).write(write_args)
        end
      end
    end
  end
end
options = {
  header: true
}
input_file = nil
output_file = nil
op = OptionParser.new do |opts|
  opts.banner = "Usage: ruby #$0 [options] file"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
  opts.on("-i", "--input=FILE", "Input file") do |i|
    input_file = i
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

if input_file
  output_file = ARGV[0]
else
  input_file = ARGV[0]
end

unless File.exist? input_file
  $stderr.puts "File not found: `#{input_file}`"
  exit
end

puts "input is #{input_file}, output is #{output_file}"

#CurlyCurly::Curly.new(input_file, output_file, options).go!
CurlyCurly::Catasta.new(input_file, output_file, options).go!