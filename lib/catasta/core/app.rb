require_relative "parser"
require_relative "../ruby/transform"
require_relative "../ruby/writer"
# require_relative "../javascript/transform"

module Catasta
  class App
    def initialize(options={})
      @options = options
    end

    def go(options={})
      merged_options = @options.merge(options)
      input = options[:input]
      template_string = if input == "-"
        ARGF.read
      else
        File.read(input)
      end
      output = options[:output]
      parsed = Parser.new.parse(template_string)
      transformed = Ruby::Transform.new.apply(parsed).generate(merged_options)
      Ruby::Writer.new(merged_options).apply(transformed)
    end
  end
end
