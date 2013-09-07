module Catasta::JavaScript
class OrExpression < Struct.new(:left, :right)
  def render(ctx)
    [left.render(ctx), "||", right.render(ctx)].join(" ")
  end
end
end