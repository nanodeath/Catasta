module Catasta::Ruby
class AtomicExpression < Struct.new(:expression)
  def render(ctx)
    ["(", expression.render(ctx), ")"].join("")
  end
end
end