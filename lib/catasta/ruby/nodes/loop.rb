require_relative "../scopes/local_scope"
require_relative "../scopes/custom_scope"

module Catasta::Ruby
class Loop < Struct.new(:loop_var, :collection, :nodes)
  def render(ctx)
    loop_scope = LocalScope.new
    loop_scope << loop_var.str

    def generate_index_variable(input)
      "_#{input[1..-1]}_index"
    end
    
    user_index_variable = "@#{loop_var.str}"
    special_loop_scope = CustomScope.new(&method(:generate_index_variable))
    special_loop_scope << user_index_variable
    
    inner = ctx.add_scope(special_loop_scope) do
      ctx.add_scope(loop_scope) do
        ctx.indent { nodes.map {|n| n.render(ctx)}.join("\n") }
      end
    end
    
    if special_loop_scope.get_resolve_count(user_index_variable) > 0
      ctx.pad %Q{#{collection.render(ctx)}.each_with_index do |#{loop_var}, #{generate_index_variable(user_index_variable)}|\n} + inner + "\n" + ctx.pad("end")
    else
      ctx.pad %Q{#{collection.render(ctx)}.each do |#{loop_var}|\n} + inner + "\n" + ctx.pad("end")
    end
  end
end
end