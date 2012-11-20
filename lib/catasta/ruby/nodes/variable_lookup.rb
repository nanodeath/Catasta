module Catasta::Ruby
class VariableLookup < Struct.new(:var)
  def render(ctx)
    var_name = var.str.to_s
    scope = ctx.scopes.find {|s| s.in_scope? var_name}
    raise "Couldn't resolve #{var_name}" unless scope
    scope.resolve(var_name)
  end
end
end
