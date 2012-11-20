require_relative "../../core/context"
require_relative "../outputter/array_buffer"
require_relative "../scopes/default_scope"

module Catasta::Ruby
class Root < Struct.new(:subtree)
  def generate(options={})
    ctx = Catasta::Context.new(:outputter => options[:outputter] || ArrayBuffer.new)
    scope = DefaultScope.new
    ctx.add_scope(scope)
    [ctx.outputter.preamble, subtree.render(ctx), ctx.outputter.postamble].compact.join("\n")
  end
end
end