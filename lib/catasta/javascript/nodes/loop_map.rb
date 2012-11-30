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
    ctx.pad %Q{#{collection.render(ctx)}.each_pair do |#{loop_key}, #{loop_value}|\n} + inner + "\nend"
  end
end
end