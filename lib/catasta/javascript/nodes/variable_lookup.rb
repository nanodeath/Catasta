module Catasta::JavaScript
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
    	<<CODE.chomp.split("\n").map {|l| ctx.pad l}.tap {|lines| lines.first.lstrip!}.join("\n")
[#{parts.map {|p| "'#{p}'"}.join(',')}].reduce(function(memo, field){
  if(memo){
    return memo[field];
  } else {
    return "";
  }
}, #{target})
CODE
	end
  end
end
end
