require_relative '../common/parser'
require_relative '../optimizers/adjacent_text_optimizer'

# Load targets
%w{ruby java15 javascript5}.each {|t| require_relative "../#{t}/generator"; require_relative "../#{t}/writer"}

# Load supporting classes
%w{front_matter_extractor embedded_commands_extractor line_number_mapper optimizer_list step}.each {|f| require_relative f}

module Catasta
  VERSION = "0.1"

  class App
    def initialize(options={})
      @options = options
    end

    def go(input_file, output_directory)
      write_args = {to_directory: Pathname.new(output_directory).to_s}

      first_step = Step.new(:First)
      first_step.tree = File.read(input_file)

      pipeline = [
        [:FrontMatter, FrontMatterExtractor.new(@options)],
        [:EmbeddedCommands, EmbeddedCommandsExtractor.new(@options)],
        [:LineNumberMapper, LineNumberMapper.new],
        [:Parser, Parser.new],
        [:CoreOptimizers, OptimizerList.new(AdjacentTextOptimizer.new)]
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

    private
    def process_steps(initial_step, subsequent_steps)
      subsequent_steps.inject(initial_step) do |last_step, (name, next_visitor)|
        step = last_step.next_step(name)
        next_visitor.visit(step)
        step
      end
    end
  end
end
