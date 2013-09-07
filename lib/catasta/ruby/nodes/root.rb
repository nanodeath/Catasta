require_relative "../../core/context"
require_relative "../outputter/array_buffer"
require_relative "../scopes/default_scope"

module Catasta::Ruby
class Root < Struct.new(:subtree)
  def generate(options={})
  	ctx = if options.is_a? Catasta::Context
  		options
  	else
  		Catasta::Context.new(outputter: options[:outputter] || ArrayBuffer.new, path: options[:path], transform: options[:transform])
  	end
    scope = DefaultScope.new
    begin
    ctx.add_scope(scope) do
      [
        ctx.outputter.preamble,
	    	subtree.render(ctx),
        ctx.outputter.postamble
      ].compact.join("\n")
    end
    rescue StandardError => e
      # puts "Subtree was #{subtree}"
      raise e
    end
  end
end
end