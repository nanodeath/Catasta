require_relative "../../core/context"
require_relative "../outputter/array_buffer"
require_relative "../scopes/default_scope"

module Catasta::JavaScript
class Root < Struct.new(:subtree)
  def generate(options={})
  	ctx = if options.is_a? Catasta::Context
  		options
  	else
  		Catasta::Context.new(outputter: options[:outputter] || ArrayBuffer.new, path: options[:path], transform: options[:transform])
  	end
    scope = DefaultScope.new
    ctx.add_scope(scope) do
	    [
	    	ctx.outputter.preamble,
	    	subtree.render(ctx),
	    	ctx.outputter.postamble
	    ].compact.map {|i| i.chomp}.join("\n") + "\n"
   	end
  end
end
end