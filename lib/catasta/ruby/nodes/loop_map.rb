require_relative "../scopes/local_scope"

module Catasta::Ruby
class LoopMap < Struct.new(:loop_key, :loop_value, :collection, :nodes)
  def render(ctx)
    s = LocalScope.new
    s << loop_key.str
    s << loop_value.str
    inner = ctx.add_scope(s) do
      ctx.indent { nodes.map {|n| n.render(ctx)}.join("\n") }
    end
    if(s.get_resolve_count(loop_key.str) > 0)
    	if(s.get_resolve_count(loop_value.str) > 0)
		    ctx.pad %Q{#{collection.render(ctx)}.each_pair do |#{loop_key}, #{loop_value}|\n} + inner + "\nend"
		else
			ctx.pad %Q{#{collection.render(ctx)}.keys.each do |#{loop_key}|\n} + inner + "\nend"
		end
	elsif(s.get_resolve_count(loop_value.str) > 0)
		ctx.pad %Q{#{collection.render(ctx)}.values.each do |#{loop_value}|\n} + inner + "\nend"
	else
		# wat
		ctx.pad %Q{#{collection.render(ctx)}.size.times do\n} + inner + "\nend"
	end
  end
end
end