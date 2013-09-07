require_relative "../scopes/local_scope"
require_relative "../scopes/custom_scope"

module Catasta::Ruby
class OrExpression < Struct.new(:left, :right)
  def render(ctx)
    [left.render(ctx), "||", right.render(ctx)].join(" ")
  end
end
end