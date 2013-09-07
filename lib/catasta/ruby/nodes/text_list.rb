module Catasta::Ruby
class TextList < Struct.new(:texts)
  def render(ctx)
    texts.map {|t| t.render(ctx)}.join("\n")
  end
end
end
