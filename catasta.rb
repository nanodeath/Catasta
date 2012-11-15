require 'yaml'
require 'benchmark'
require 'optparse'
require 'pathname'

require 'term/ansicolor'
class String
  include Term::ANSIColor
end

require_relative 'common/parser'
require_relative 'optimizers/adjacent_text_optimizer'
require_relative 'ruby/generator'
require_relative 'ruby/writer'
require_relative 'java15/generator'
require_relative 'java15/writer'
require_relative 'javascript5/generator'
require_relative 'javascript5/writer'

module Catasta
VERSION = "0.1"
class Step
  def initialize(name, previous_step=nil)
    @name = name
    @previous_step = previous_step
    @tree = nil
    @data = {}
  end
  def next_step(name)
    self.class.new(name, self)
  end
  def tree=(tree)
    @tree = tree
  end
  def tree(copy_previous=true)
    if @tree
      @tree
    elsif @previous_step
      if copy_previous
        @tree = Marshal.load(Marshal.dump(@previous_step.tree(false)))
        @tree
      else
        @previous_step.tree(false)
      end
    else
      nil
    end
  end
  def lookup(name)
    if @name == name
      self
    elsif @previous_step
      @previous_step.lookup(name)
    else
      nil
    end
  end
  def [](key)
    @data[key]
  end
  def []=(key, value)
    @data[key] = value
  end
end

class FrontMatter
  def initialize(ops)
    @ops = ops
  end
  def visit(step)
    step.tree.gsub!(/^(---.*)---\n/m) {|m| @front_matter = YAML.load_documents(m); ""}
    @front_matter = @front_matter.compact.inject({}){|memo, doc| memo[doc["target"]] = doc; memo}
    (@front_matter[nil] ||= {})["header"] = @ops[:header]
    @front_matter.each do |target, doc|
      next if target.nil?
      doc.replace(@front_matter[nil].merge(doc))
    end
    # @front_matter["Java"] = @front_matter["Java15"]
    # @front_matter["Ruby"] = @front_matter["Ruby19"]
    step[:front_matter] = @front_matter
  end
end
class EmbeddedCommandsExtractor
  def initialize(ops)
    @ops = ops
    @commands = []
  end
  def visit(step)
    step.tree.gsub!(/{{(.+?)}}/) {|m| @commands.push($1); "{{#{@commands.size-1}}}"}
    step[:commands] = @commands
  end
end
class SourceVisitor
  def initialize
    @source = {}
  end
  
  def visit(step)
    step.tree.split("\n").each_with_index do |line, idx|
      visit_line(line, idx+1)
    end
    step[:visitor] = self
  end

  def get_line(line_number)
    @source[line_number_to_key(line_number)]
  end

  private
  def visit_line(line, line_number)
    @source[line_number_to_key(line_number)] = line
  end
  def line_number_to_key(line_number)
    :"line_#{line_number}"
  end
end

class Optimizers
  def initialize(*optimizers)
    @optimizers = optimizers
  end
  def visit(step)
    @optimizers.each do |o|
      o.optimize! step.tree
    end
  end
end

class App
  def initialize(options={})
    @options = options
  end

  def process_steps(initial_step, subsequent_steps)
    subsequent_steps.inject(initial_step) do |last_step, (name, next_visitor)|
      step = last_step.next_step(name)
      next_visitor.visit(step)
      step
    end
  end

  def go(input_file, output_directory)
    write_args = {to_directory: Pathname.new(output_directory).to_s}

    first_step = Step.new(:First)
    first_step.tree = File.read(input_file)

    pipeline = [
      [:FrontMatter, FrontMatter.new(@options)],
      [:EmbeddedCommands, EmbeddedCommandsExtractor.new(@options)],
      [:SourceVisitor, SourceVisitor.new],
      [:Parser, Parser.new],
      [:CoreOptimizers, Optimizers.new(AdjacentTextOptimizer.new)]
    ]
    pre_code_step = process_steps(first_step, pipeline)

    targets = @options[:targets]
    if(targets.nil? or !(["Ruby", "Ruby19"] & targets).empty?)
      process_steps(pre_code_step, [
        [:RubyGenerator, Ruby::Generator.new],
        [:RubyWriter, Ruby::Writer.new(write_args)]
      ])
    end
    if(targets.nil? or !(["Java", "Java15"] & targets).empty?)
      process_steps(pre_code_step, [
        [:JavaGenerator, Java15::Generator.new],
        [:JavaWriter, Java15::Writer.new(write_args)]
      ])
    end
    if(targets.nil? or !(["JavaScript", "JavaScript5"] & targets).empty?)
      process_steps(pre_code_step, [
        [:JavascriptGenerator, Javascript5::Generator.new],
        [:JavascriptWriter, Javascript5::Writer.new(write_args)]
      ])
    end
  end
end
end

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