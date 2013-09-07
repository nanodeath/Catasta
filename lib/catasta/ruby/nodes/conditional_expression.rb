module Catasta::Ruby
class ConditionalExpression < Struct.new(:condition, :nodes, :elsif_nodes, :else_content)
  def render(ctx)
    rendered_conditions = condition.render(ctx)

    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    elsif_nodes.each do |elsif_node|
    	rendered_elsif_conditions = elsif_node.condition.render(ctx)
    	inner << ctx.pad("elsif(#{rendered_elsif_conditions})") << ctx.indent { elsif_node.nodes.map {|n| n.render(ctx)} }
    end
    if else_content
    	inner << "else" << ctx.indent { else_content.nodes.map {|n| n.render(ctx)} }
    end
    [ctx.pad("if(#{rendered_conditions})"), inner, ctx.pad("end")].flatten.join("\n")
  end
end
end
