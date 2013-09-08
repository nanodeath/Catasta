require_relative "parser"
require 'pp'

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
      ast = Parser.new.parse(template_string)

      # ruby_ast = Ruby::Transform.new.apply(ast)
      # ruby_code = ruby_ast.generate(merged_options)
      # Ruby::Writer.new(merged_options).apply(ruby_code)

      # js_ast = JavaScript::Transform.new.apply(ast)
      # ruby_code = js_ast.generate(merged_options)
      # JavaScript::Writer.new(merged_options).apply(ruby_code)
    end
  end
end
