module Catasta::JavaScript
class ConditionalExpression < Struct.new(:condition, :nodes, :else_content)
  def render(ctx)
    rendered_conditions = condition.render(ctx)

    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    if else_content
    	inner << "} else {" << ctx.indent { else_content.nodes.map {|n| n.render(ctx)} }
    end
    [ctx.pad("if(#{rendered_conditions}) {"), inner, ctx.pad("}")].flatten.join("\n")
  end
end
end
