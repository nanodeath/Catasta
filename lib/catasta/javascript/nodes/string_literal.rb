module Catasta::JavaScript
class StringLiteral < Struct.new(:string)
  def render(ctx)
    %Q{"#{string}"}
  end
end
end
