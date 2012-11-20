require_relative "parser"
require_relative "../ruby/transform"

module Catasta
  class App
    def initialize(options={})
      @options = options
    end

    def go(template_string, options={})
      parsed = Parser.new.parse(template_string)
      transformed = Ruby::Transform.new.apply(parsed).generate
      return transformed
    end
  end
end
