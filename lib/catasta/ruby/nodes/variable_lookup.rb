module Catasta::Ruby
class VariableLookup < Struct.new(:var)
  def render(ctx)
    var_name = var.str.to_s
    parts = nil
    if var_name.include?(".")
    	parts = var_name.split(".")
    	var_name = parts.shift
    end
    scope = ctx.scopes.find {|s| s.in_scope? var_name}
    raise "Couldn't resolve #{var_name}" unless scope
    target = scope.resolve(var_name)
    if !parts
    	target
    else
    	<<CODE.chomp
[#{parts.map {|p| ":#{p}"}.join(',')}].inject(#{target}) {|memo, val|
  if memo != ""
    memo = if memo.respond_to?(val)
      memo.send(val)
    elsif memo.respond_to?(:[])
      memo[val]
    else
      ""
    end
  end
  memo
}
CODE
	end
  end
end
end
