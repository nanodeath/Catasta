module Catasta::JavaScript
class Content < Struct.new(:nodes)
  def render(ctx)
    nodes.map {|n| n.render(ctx)}.join("\n") + "\n"
  end
end
end
