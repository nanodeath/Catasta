module Catasta::JavaScript
class Conditional < Struct.new(:inverted, :variable, :nodes)
  def render(ctx)
    rendered_variable = variable.render(ctx)
    condition = inverted ? get_inverted_condition(rendered_variable) : get_condition(rendered_variable)
    condition = condition.map {|i| "(#{i})"}.join(" || ")
    inner = ctx.indent { nodes.map {|n| n.render(ctx)} }
    [ctx.pad("if(#{condition}) {"), inner, ctx.pad("}")].flatten.join("\n")
  end

  private
  def get_condition(rendered_variable)
    [
      rendered_variable + " === true", # Booleans
      %Q{typeof #{rendered_variable} === "string" && #{rendered_variable} !== ""}, # Strings
      %Q{typeof #{rendered_variable} === "number" && #{rendered_variable} !== 0}, # Numbers
      %Q{typeof #{rendered_variable} === "object" && Object.keys(#{rendered_variable}).length > 0} # Objects and arrays
    ]
  end

  def get_inverted_condition(rendered_variable)
    [
      rendered_variable + " === null", # Nil
      rendered_variable + " === false", # Booleans
      rendered_variable + %q{ === ""}, # Strings
      %Q{#{rendered_variable} === 0}, # Numbers
      %Q{typeof #{rendered_variable} === "object" && Object.keys(#{rendered_variable}).length === 0} # Objects and arrays
    ]
  end
end
end
