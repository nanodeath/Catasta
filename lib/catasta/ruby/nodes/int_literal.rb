module Catasta::Ruby
class IntLiteral < Struct.new(:literal)
  def render(ctx)
    literal
  end
end
end
