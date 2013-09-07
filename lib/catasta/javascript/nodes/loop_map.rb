require_relative "../scopes/local_scope"

module Catasta::JavaScript
class LoopMap < Struct.new(:loop_key, :loop_value, :collection, :nodes)
  def render(ctx)
    s = LocalScope.new
    s << loop_key.str
    s << loop_value.str
    inner = ctx.add_scope(s) do
      ctx.indent { nodes.map {|n| n.render(ctx)}.join("\n") }
    end

    inner = ctx.indent { ctx.pad("var #{loop_value} = #{collection.render(ctx)}[#{loop_key}];\n") } + inner
    ctx.pad %Q<Object.keys(#{collection.render(ctx)}).forEach(function(#{loop_key}){\n> + inner + "\n}"
  end
end
end