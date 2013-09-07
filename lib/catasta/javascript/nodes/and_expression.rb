module Catasta::JavaScript
class AndExpression < Struct.new(:left, :right)
  def render(ctx)
    [left.render(ctx), "&&", right.render(ctx)].join(" ")
  end
end
end