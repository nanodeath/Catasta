module Catasta::Ruby
class ConditionalExpression < Struct.new(:condition, :nodes)
  def render(ctx)
    rendered_conditions = condition.render(ctx)

    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    [ctx.pad("if(#{rendered_conditions})"), inner, ctx.pad("end")].flatten.join("\n")
  end
end
end
